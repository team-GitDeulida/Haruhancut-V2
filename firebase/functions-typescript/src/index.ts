import * as admin from "firebase-admin";

import "./config";
import {
  addNewUserHaruhancut,
  markUserDeletedInSheet,
  notifyOnNewComment,
  notifyOnNewPost,
} from "./haruhancut";

/**
 * 필수 환경 변수를 읽습니다.
 * @param name 환경 변수 이름
 * @returns 환경 변수 값
 */
function getRequiredEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

const firebaseProjectId = getRequiredEnv("APP_PROJECT_ID");
const firebaseDatabaseUrl = getRequiredEnv("APP_DATABASE_URL");
const serviceAccountClientEmail =
  process.env.GOOGLE_SERVICE_ACCOUNT_CLIENT_EMAIL;
const serviceAccountPrivateKey =
  process.env.GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY ?
    process.env.GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY.replace(/\\n/g, "\n") :
    undefined;
const serviceAccountProjectId =
  process.env.GOOGLE_SERVICE_ACCOUNT_PROJECT_ID || firebaseProjectId;

const credential =
  serviceAccountClientEmail && serviceAccountPrivateKey ?
    admin.credential.cert({
      projectId: serviceAccountProjectId,
      clientEmail: serviceAccountClientEmail,
      privateKey: serviceAccountPrivateKey,
    }) :
    admin.credential.applicationDefault();

admin.initializeApp({
  credential,
  databaseURL: firebaseDatabaseUrl,
  projectId: firebaseProjectId,
});

export {
  addNewUserHaruhancut,
  markUserDeletedInSheet,
  notifyOnNewComment,
  notifyOnNewPost,
};
