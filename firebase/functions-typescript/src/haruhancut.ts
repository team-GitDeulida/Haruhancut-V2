import * as admin from "firebase-admin";
import {
  onValueDeleted,
  onValueWritten,
} from "firebase-functions/v2/database";
import {google, sheets_v4} from "googleapis";
import nodemailer from "nodemailer";

import "./config";

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

const GMAIL_EMAIL = getRequiredEnv("GMAIL_EMAIL");
const GMAIL_PASSWORD = getRequiredEnv("GMAIL_APP_PASSWORD");
const ADMIN_NOTIFICATION_EMAIL =
  process.env.ADMIN_NOTIFICATION_EMAIL || GMAIL_EMAIL;
const SHEET_ID = getRequiredEnv("GOOGLE_SHEETS_ID");
const serviceAccountClientEmail = getRequiredEnv(
    "GOOGLE_SERVICE_ACCOUNT_CLIENT_EMAIL",
);
const serviceAccountPrivateKey = getRequiredEnv(
    "GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY",
).replace(/\\n/g, "\n");
const serviceAccountProjectId =
  process.env.GOOGLE_SERVICE_ACCOUNT_PROJECT_ID ||
  getRequiredEnv("APP_PROJECT_ID");

const transporter = nodemailer.createTransport({
  host: "smtp.gmail.com",
  port: 465,
  secure: true,
  auth: {
    user: GMAIL_EMAIL,
    pass: GMAIL_PASSWORD,
  },
  tls: {
    rejectUnauthorized: false,
  },
});

const SCOPES = ["https://www.googleapis.com/auth/spreadsheets"];

/**
 * Google Sheets API 클라이언트를 반환합니다.
 * @returns sheets client
 */
async function getGoogleSheetsClient(): Promise<sheets_v4.Sheets> {
  const auth = new google.auth.GoogleAuth({
    credentials: {
      client_email: serviceAccountClientEmail,
      private_key: serviceAccountPrivateKey,
      project_id: serviceAccountProjectId,
    },
    scopes: SCOPES,
  });
  return google.sheets({version: "v4", auth});
}

/**
 * Firebase Authentication에서 UID로 이메일을 가져옵니다.
 * @param userId 사용자 UID
 * @returns 이메일 또는 "이메일 없음"
 */
async function getUserEmail(userId: string): Promise<string> {
  try {
    const userRecord = await admin.auth().getUser(userId);
    return userRecord.email || "이메일 없음";
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.error(`❌ Firebase에서 이메일 가져오기 실패: ${message}`);
    return "이메일 없음";
  }
}

/**
 * 구글 시트의 Haruhancut 시트에 있는 유저 정보를 업데이트합니다.
 * @param userData 사용자 데이터 객체
 */
async function updateUserInGoogleSheet(userData: any): Promise<void> {
  try {
    const email = await getUserEmail(userData.uid);
    const sheets = await getGoogleSheetsClient();

    const readRes = await sheets.spreadsheets.values.get({
      spreadsheetId: SHEET_ID,
      range: "Users!A:H",
    });

    const values = readRes.data.values || [];
    const userRowIndex = values.findIndex((row) => row[1] === userData.uid);

    if (userRowIndex !== -1) {
      values[userRowIndex] = [
        userData.nickname,
        userData.uid,
        userData.loginPlatform,
        userData.birthdayDate,
        userData.registerDate,
        email,
        "",
      ];

      await sheets.spreadsheets.values.update({
        spreadsheetId: SHEET_ID,
        range: `Users!A${userRowIndex + 1}:H${userRowIndex + 1}`,
        valueInputOption: "RAW",
        requestBody: {values: [values[userRowIndex]]},
      });
      console.log(`✅ 구글 시트 업데이트 완료: ${userData.uid}`);
    } else {
      console.log(`⚠️ 업데이트할 유저를 찾을 수 없음: ${userData.uid}`);
    }
  } catch (error) {
    console.error("❌ 구글 시트 업데이트 오류:", error);
  }
}

/**
 * 유저가 처음 닉네임을 설정할 때 구글 시트에 추가하고 메일을 전송합니다.
 * @param userData 사용자 데이터 객체
 */
async function addUserToGoogleSheet(userData: any): Promise<void> {
  try {
    const email = await getUserEmail(userData.uid);
    const sheets = await getGoogleSheetsClient();

    await sheets.spreadsheets.values.append({
      spreadsheetId: SHEET_ID,
      range: "Users!A:H",
      valueInputOption: "RAW",
      requestBody: {
        values: [[
          userData.nickname,
          userData.uid,
          userData.loginPlatform,
          userData.birthdayDate,
          userData.registerDate,
          email,
          "",
        ]],
      },
    });
    console.log(`✅ 새로운 유저 추가: ${userData.uid}`);

    await transporter.sendMail({
      from: GMAIL_EMAIL,
      to: ADMIN_NOTIFICATION_EMAIL,
      subject: "[하루한컷] 새 사용자가 가입했습니다.",
      text: `📢 새 사용자 정보:
닉네임: ${userData.nickname}
ID: ${userData.uid}
플랫폼: ${userData.loginPlatform}
생일: ${userData.birthdayDate}
가입 날짜: ${userData.registerDate}
이메일: ${email}`,
    });
    console.log("✅ 관리자에게 메일 전송 성공!");
  } catch (error) {
    console.error("❌ 유저 추가 오류:", error);
  }
}

/**
 * 유저 삭제를 감지하여 구글 시트에서 탈퇴 처리합니다.
 * @param userId 사용자 UID
 */
async function markUserAsDeleted(userId: string): Promise<void> {
  try {
    const sheets = await getGoogleSheetsClient();

    const readRes = await sheets.spreadsheets.values.get({
      spreadsheetId: SHEET_ID,
      range: "Users!A:H",
    });

    const values = readRes.data.values || [];
    const userRowIndex = values.findIndex((row) => row[1] === userId);

    if (userRowIndex !== -1) {
      values[userRowIndex][6] = "탈퇴";

      await sheets.spreadsheets.values.update({
        spreadsheetId: SHEET_ID,
        range: `Users!A${userRowIndex + 1}:H${userRowIndex + 1}`,
        valueInputOption: "RAW",
        requestBody: {values: [values[userRowIndex]]},
      });
      console.log(`🚨 유저 삭제 감지 - 탈퇴 처리 완료: ${userId}`);
    } else {
      console.log(`⚠️ 삭제된 유저를 찾을 수 없음: ${userId}`);
    }
  } catch (error) {
    console.error("❌ 구글 시트 탈퇴 처리 오류:", error);
  }
}

export const addNewUserHaruhancut = onValueWritten(
    {
      region: "us-central1",
      ref: "/users/{uid}",
    },
    async (event) => {
      const beforeData = event.data.before.val();
      const afterData = event.data.after.val();

      if (!afterData) {
        console.error("❌ 오류: 데이터 없음");
        return;
      }

      if ((!beforeData || !beforeData.nickname) && afterData.nickname) {
        console.log(`📢 새로운 닉네임 생성 감지: ${afterData.nickname}`);
        await addUserToGoogleSheet(afterData);
      } else {
        console.log(`ℹ️ 기존 유저 정보 업데이트 감지: ${afterData.uid}`);
        await updateUserInGoogleSheet(afterData);
      }
    },
);

export const markUserDeletedInSheet = onValueDeleted(
    {
      region: "us-central1",
      ref: "/users/{uid}",
    },
    async (event) => {
      const uid = event.params.uid;
      console.log(`🚨 유저 삭제 감지: ${uid}`);
      await markUserAsDeleted(uid);
    },
);

export const notifyOnNewPost = onValueWritten(
    {
      region: "us-central1",
      ref: "/groups/{groupId}/postsByDate/{date}/{postId}",
    },
    async (event) => {
      const before = event.data.before.val();
      const after = event.data.after.val();
      if (before || !after) {
        return;
      }

      const {groupId, postId} = event.params;
      const senderId = after.userId;
      const senderNickname = after.nickname;

      const membersSnap = await admin.database()
          .ref(`/groups/${groupId}/members`)
          .once("value");

      const tokens: string[] = [];
      for (const [uid] of Object.entries(membersSnap.val() || {})) {
        if (uid === senderId) continue;
        const fcmSnap = await admin.database()
            .ref(`/users/${uid}/fcmToken`)
            .once("value");
        const token = fcmSnap.val();
        if (typeof token === "string" && token !== "noFCM") {
          tokens.push(token.trim());
        }
      }

      if (tokens.length === 0) {
        console.log("❌ FCM 토큰이 없습니다.");
        return;
      }

      const batchSize = 500;
      let totalSuccess = 0;
      let totalFailure = 0;

      for (let i = 0; i < tokens.length; i += batchSize) {
        const batch = tokens.slice(i, i + batchSize);
        const multicastMsg = {
          tokens: batch,
          notification: {
            title: `${senderNickname}님이 사진을 올렸어요!`,
            body: "오늘의 한 컷을 확인해보세요 📸",
          },
          data: {type: "post", groupId, postId, senderId, senderNickname},
        };

        const resp = await admin.messaging().sendEachForMulticast(multicastMsg);
        totalSuccess += resp.successCount;
        totalFailure += resp.failureCount;

        resp.responses.forEach((response, idx) => {
          if (!response.success) {
            console.error(`❌ [${batch[idx]}] 발송 실패:`, response.error);
          }
        });
      }

      console.log(
          `✅ 게시글 알림 완료: 성공 ${totalSuccess}건, 실패 ${totalFailure}건`,
      );
    },
);

export const notifyOnNewComment = onValueWritten(
    {
      region: "us-central1",
      ref: "/groups/{groupId}/postsByDate/{date}/{postId}/comments/{commentId}",
    },
    async (event) => {
      const before = event.data.before.val();
      const after = event.data.after.val();
      if (before || !after) {
        return;
      }

      const {groupId, postId} = event.params;
      const senderId = after.userId;
      const senderNickname = after.nickname;

      const membersSnap = await admin.database()
          .ref(`/groups/${groupId}/members`)
          .once("value");

      const tokens: string[] = [];
      for (const [uid] of Object.entries(membersSnap.val() || {})) {
        if (uid === senderId) continue;
        const fcmSnap = await admin.database()
            .ref(`/users/${uid}/fcmToken`)
            .once("value");
        const token = fcmSnap.val();
        if (typeof token === "string" && token !== "noFCM") {
          tokens.push(token.trim());
        }
      }

      if (tokens.length === 0) {
        console.log("❌ FCM 토큰이 없습니다.");
        return;
      }

      const batchSize = 500;
      let totalSuccess = 0;
      let totalFailure = 0;

      for (let i = 0; i < tokens.length; i += batchSize) {
        const batch = tokens.slice(i, i + batchSize);
        const multicastMsg = {
          tokens: batch,
          notification: {
            title: `${senderNickname}님이 댓글을 달았어요 💬`,
            body: (after.text || "").slice(0, 30) || "새로운 댓글이 있습니다.",
          },
          data: {
            type: "comment",
            groupId,
            postId,
            senderId,
            senderNickname,
          },
        };

        const resp = await admin.messaging().sendEachForMulticast(multicastMsg);
        totalSuccess += resp.successCount;
        totalFailure += resp.failureCount;

        resp.responses.forEach((response, idx) => {
          if (!response.success) {
            console.error(`❌ [${batch[idx]}] 발송 실패:`, response.error);
          }
        });
      }

      console.log(
          `✅ 댓글 알림 완료: 성공 ${totalSuccess}건, 실패 ${totalFailure}건`,
      );
    },
);
