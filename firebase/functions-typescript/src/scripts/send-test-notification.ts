import * as admin from "firebase-admin";

import {
  createApnsAlertConfig,
  getNickname,
  getValidFcmToken,
  initializeFirebaseAdmin,
  maskToken,
  NotificationUserData,
} from "./notification-utils";

/**
 * 명령행 인자 또는 환경 변수에서 테스트 대상 사용자 UID를 읽습니다.
 * @returns 사용자 UID
 */
function getTargetUserId(): string {
  const positionalArgument = process.argv
      .slice(2)
      .find((argument) => !argument.startsWith("--"));
  const userId =
    positionalArgument?.trim() ||
    process.env.TEST_NOTIFICATION_USER_ID?.trim();

  if (!userId) {
    throw new Error(
        "User ID is required. Run " +
        "`npm run notification:test -- <user-id>` or set " +
        "TEST_NOTIFICATION_USER_ID in .env.",
    );
  }
  return userId;
}

/**
 * Realtime Database에서 사용자와 FCM 토큰을 조회해 테스트 알림을 보냅니다.
 */
async function main(): Promise<void> {
  const userId = getTargetUserId();
  const dryRun = process.argv.includes("--dry-run");
  const title =
    process.env.TEST_NOTIFICATION_TITLE?.trim() ||
    "🔔 하루한컷 테스트 알림";
  const body =
    process.env.TEST_NOTIFICATION_BODY?.trim() ||
    "Cloud Functions TypeScript에서 보낸 테스트 알림입니다.";
  const app = initializeFirebaseAdmin();

  try {
    const snapshot = await admin.database()
        .ref(`/users/${userId}`)
        .once("value");
    const user = snapshot.val() as NotificationUserData | null;

    if (!user || typeof user !== "object") {
      throw new Error(`User not found: ${userId}`);
    }

    const nickname = getNickname(user);

    if (user.isPushEnabled !== true) {
      throw new Error(`${nickname} 사용자는 알림 설정이 꺼져 있습니다.`);
    }

    const token = getValidFcmToken(user.fcmToken);

    if (!token) {
      throw new Error(`${nickname} 사용자의 유효한 FCM 토큰이 없습니다.`);
    }

    console.log(`➡️ 사용자: ${nickname}`);
    console.log(`➡️ FCM 토큰: ${maskToken(token)}`);
    console.log(`➡️ 전송 모드: ${dryRun ? "검증만 수행" : "실제 전송"}`);

    const messageId = await admin.messaging().send(
        {
          token,
          notification: {
            title,
            body,
          },
          data: {
            type: "test",
            userId,
          },
          apns: createApnsAlertConfig(),
        },
        dryRun,
    );

    console.log(
        `${dryRun ? "✅ FCM 메시지 검증 성공" : "✅ FCM 전송 요청 성공"}: ` +
        messageId,
    );
  } finally {
    await app.delete();
  }
}

main().catch((error: unknown) => {
  const message = error instanceof Error ? error.message : String(error);
  console.error(`❌ 테스트 알림 처리 실패: ${message}`);
  process.exitCode = 1;
});
