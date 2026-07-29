import * as admin from "firebase-admin";

import "../config";

export interface NotificationUserData {
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
export function initializeFirebaseAdmin(): admin.app.App {
  if (admin.apps.length > 0) {
    return admin.app();
  }

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
 * 사용자 데이터에서 화면에 표시할 닉네임을 읽습니다.
 * @param user 사용자 데이터
 * @returns 닉네임
 */
export function getNickname(user: NotificationUserData): string {
  return typeof user.nickname === "string" && user.nickname.trim() ?
    user.nickname.trim() :
    "알 수 없는 사용자";
}

/**
 * 사용자 데이터의 FCM 토큰이 유효한 문자열인지 확인합니다.
 * @param value FCM 토큰 후보
 * @returns 유효한 토큰 또는 null
 */
export function getValidFcmToken(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }

  const token = value.trim();
  return invalidTokens.has(token) ? null : token;
}

/**
 * 로그에 FCM 토큰 전체가 노출되지 않도록 일부만 남깁니다.
 * @param token FCM 토큰
 * @returns 마스킹된 토큰
 */
export function maskToken(token: string): string {
  if (token.length <= 14) {
    return "***";
  }
  return `${token.slice(0, 8)}...${token.slice(-6)}`;
}

/**
 * iOS 배너와 기본 알림음에 필요한 APNs 설정을 생성합니다.
 * @returns APNs alert 설정
 */
export function createApnsAlertConfig(): admin.messaging.ApnsConfig {
  return {
    headers: {
      "apns-priority": "10",
      "apns-push-type": "alert",
    },
    payload: {
      aps: {
        sound: "default",
      },
    },
  };
}
