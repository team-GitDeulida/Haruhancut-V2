/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// npm install googleapis
// npm install nodemailer

// npm run lint -- --fix
// firebase deploy --only functions

require("dotenv").config();

// Index.js 파일
const admin = require("firebase-admin");

/**
 * 필수 환경 변수를 읽습니다.
 * @param {string} name 환경 변수 이름
 * @return {string} 환경 변수 값
 */
function getRequiredEnv(name) {
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

// 새로 추가한 Eummeyo 함수 모듈 불러오기
const {
  addNewUserHaruhancut,
  markUserDeletedInSheet,
  notifyOnNewPost,
  notifyOnNewComment,
} = require("./haruhancut");

exports.addNewUserHaruhancut = addNewUserHaruhancut;
exports.markUserDeletedInSheet = markUserDeletedInSheet;
exports.notifyOnNewPost = notifyOnNewPost;
exports.notifyOnNewComment = notifyOnNewComment;
