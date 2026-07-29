import * as admin from "firebase-admin";

import {
  createApnsAlertConfig,
  getNickname,
  getValidFcmToken,
  initializeFirebaseAdmin,
  maskToken,
  NotificationUserData,
} from "./notification-utils";

interface Recipient {
  userId: string;
  nickname: string;
  token: string;
}

interface RecipientResult {
  recipients: Recipient[];
  disabledCount: number;
  invalidTokenCount: number;
  duplicateTokenCount: number;
}

const multicastBatchSize = 500;

/**
 * 명령행 옵션 뒤의 문자열 값을 읽습니다.
 * @param optionName 옵션 이름
 * @returns 옵션 값 또는 undefined
 */
function getOptionValue(optionName: string): string | undefined {
  const optionIndex = process.argv.indexOf(optionName);
  if (optionIndex < 0) {
    return undefined;
  }

  const value = process.argv[optionIndex + 1]?.trim();
  if (!value || value.startsWith("--")) {
    throw new Error(`${optionName} 뒤에 값을 입력해야 합니다.`);
  }
  return value;
}

/**
 * 명령행 옵션 또는 환경 변수에서 공지 내용을 읽습니다.
 * @param optionName 명령행 옵션 이름
 * @param envName 환경 변수 이름
 * @returns 공지 문자열
 */
function getRequiredAnnouncementText(
    optionName: string,
    envName: string,
): string {
  const value =
    getOptionValue(optionName) ||
    process.env[envName]?.trim();

  if (!value) {
    throw new Error(
        `${optionName} 또는 ${envName} 환경 변수로 공지 내용을 입력해야 합니다.`,
    );
  }
  return value.replace(/\\n/g, "\n");
}

/**
 * Realtime Database 사용자 중 공지 알림 수신 대상을 반환합니다.
 * @returns 수신 대상 및 제외 사유별 개수
 */
async function getRecipients(): Promise<RecipientResult> {
  const snapshot = await admin.database()
      .ref("/users")
      .once("value");
  const users = snapshot.val() as
    Record<string, NotificationUserData> | null;

  if (!users || typeof users !== "object") {
    throw new Error("Realtime Database에 사용자 데이터가 없습니다.");
  }

  const recipientsByToken = new Map<string, Recipient>();
  let disabledCount = 0;
  let invalidTokenCount = 0;
  let duplicateTokenCount = 0;

  for (const [userId, user] of Object.entries(users)) {
    if (!user || typeof user !== "object") {
      invalidTokenCount += 1;
      continue;
    }

    if (user.isPushEnabled !== true) {
      disabledCount += 1;
      continue;
    }

    const token = getValidFcmToken(user.fcmToken);
    if (!token) {
      invalidTokenCount += 1;
      continue;
    }

    if (recipientsByToken.has(token)) {
      duplicateTokenCount += 1;
      continue;
    }

    recipientsByToken.set(token, {
      userId,
      nickname: getNickname(user),
      token,
    });
  }

  return {
    recipients: Array.from(recipientsByToken.values()),
    disabledCount,
    invalidTokenCount,
    duplicateTokenCount,
  };
}

/**
 * 전체 수신 대상을 500개 단위로 나누어 공지 알림을 전송합니다.
 */
async function main(): Promise<void> {
  const dryRun = process.argv.includes("--dry-run");
  const confirmed = process.argv.includes("--confirm");
  const title = getRequiredAnnouncementText(
      "--title",
      "ANNOUNCEMENT_TITLE",
  );
  const body = getRequiredAnnouncementText(
      "--body",
      "ANNOUNCEMENT_BODY",
  );

  if (!dryRun && !confirmed) {
    throw new Error(
        "전체 공지 실제 전송에는 --confirm 옵션이 필요합니다. " +
        "먼저 --dry-run으로 검증하세요.",
    );
  }

  const app = initializeFirebaseAdmin();

  try {
    const {
      recipients,
      disabledCount,
      invalidTokenCount,
      duplicateTokenCount,
    } = await getRecipients();

    if (recipients.length === 0) {
      throw new Error("공지 알림을 받을 수 있는 사용자가 없습니다.");
    }

    console.log(`➡️ 공지 제목: ${title}`);
    console.log(`➡️ 공지 본문: ${body}`);
    console.log(`➡️ 전송 모드: ${dryRun ? "검증만 수행" : "실제 전송"}`);
    console.log(`➡️ 전송 대상: ${recipients.length}명`);
    console.log(`➡️ 알림 비활성화 제외: ${disabledCount}명`);
    console.log(`➡️ 유효하지 않은 토큰 제외: ${invalidTokenCount}명`);
    console.log(`➡️ 중복 토큰 제외: ${duplicateTokenCount}명`);

    let totalSuccess = 0;
    let totalFailure = 0;

    for (
      let startIndex = 0;
      startIndex < recipients.length;
      startIndex += multicastBatchSize
    ) {
      const batch = recipients.slice(
          startIndex,
          startIndex + multicastBatchSize,
      );
      const response = await admin.messaging().sendEachForMulticast(
          {
            tokens: batch.map((recipient) => recipient.token),
            notification: {
              title,
              body,
            },
            data: {
              type: "announcement",
            },
            apns: createApnsAlertConfig(),
          },
          dryRun,
      );

      totalSuccess += response.successCount;
      totalFailure += response.failureCount;

      response.responses.forEach((result, index) => {
        if (result.success) {
          return;
        }

        const recipient = batch[index];
        const errorCode = result.error?.code || "unknown";
        console.error(
            `❌ ${recipient.nickname} ` +
            `(${maskToken(recipient.token)}) 전송 실패: ${errorCode}`,
        );
      });
    }

    console.log(
        `${dryRun ? "✅ 전체 공지 검증 완료" : "✅ 전체 공지 전송 완료"}: ` +
        `성공 ${totalSuccess}건, 실패 ${totalFailure}건`,
    );

    if (totalFailure > 0) {
      process.exitCode = 1;
    }
  } finally {
    await app.delete();
  }
}

main().catch((error: unknown) => {
  const message = error instanceof Error ? error.message : String(error);
  console.error(`❌ 전체 공지 처리 실패: ${message}`);
  process.exitCode = 1;
});
