import * as admin from "firebase-admin";

import "../config";

interface UserData {
  nickname?: unknown;
  isPushEnabled?: unknown;
  fcmToken?: unknown;
}

const invalidTokens = new Set(["", "noFCM", "noToken"]);

/**
 * 필수 환경 변수를 읽습니다.
 * @param name 환경 변수 이름
 * @returns 환경 변수 값
 */
function getRequiredEnv(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

/**
 * Cloud Functions와 같은 환경 변수로 Firebase Admin SDK를 초기화합니다.
 * @returns 초기화된 Firebase 앱
 */
function initializeFirebaseAdmin(): admin.app.App {
  const projectId = getRequiredEnv("APP_PROJECT_ID");
  const databaseURL = getRequiredEnv("APP_DATABASE_URL");
  const clientEmail = process.env.GOOGLE_SERVICE_ACCOUNT_CLIENT_EMAIL?.trim();
  const privateKeyValue =
    process.env.GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY;
  const privateKey = privateKeyValue?.replace(/\\n/g, "\n");

  if ((clientEmail && !privateKey) || (!clientEmail && privateKey)) {
    throw new Error(
        "Both GOOGLE_SERVICE_ACCOUNT_CLIENT_EMAIL and " +
        "GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY must be provided together.",
    );
  }

  const credential =
    clientEmail && privateKey ?
      admin.credential.cert({
        projectId:
          process.env.GOOGLE_SERVICE_ACCOUNT_PROJECT_ID?.trim() || projectId,
        clientEmail,
        privateKey,
      }) :
      admin.credential.applicationDefault();

  return admin.initializeApp({
    credential,
    databaseURL,
    projectId,
  });
}

/**
 * 로그에 FCM 토큰 전체가 노출되지 않도록 일부만 남깁니다.
 * @param token FCM 토큰
 * @returns 마스킹된 토큰
 */
function maskToken(token: string): string {
  if (token.length <= 14) {
    return "***";
  }
  return `${token.slice(0, 8)}...${token.slice(-6)}`;
}

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
    const user = snapshot.val() as UserData | null;

    if (!user || typeof user !== "object") {
      throw new Error(`User not found: ${userId}`);
    }

    const nickname =
      typeof user.nickname === "string" && user.nickname.trim() ?
        user.nickname.trim() :
        "알 수 없는 사용자";

    if (user.isPushEnabled !== true) {
      throw new Error(`${nickname} 사용자는 알림 설정이 꺼져 있습니다.`);
    }

    const token =
      typeof user.fcmToken === "string" ?
        user.fcmToken.trim() :
        "";

    if (invalidTokens.has(token)) {
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
          apns: {
            headers: {
              "apns-priority": "10",
              "apns-push-type": "alert",
            },
            payload: {
              aps: {
                sound: "default",
              },
            },
          },
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
