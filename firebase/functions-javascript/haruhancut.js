// haruhancut.js
const {
  onValueWritten,
  onValueDeleted,
} = require("firebase-functions/v2/database");
const admin = require("firebase-admin");
const {google} = require("googleapis");
const nodemailer = require("nodemailer");

// NOTE: admin.initializeApp()는 index.js에서 호출하므로 여기서는 재호출하지 않습니다.

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

// ✅ Nodemailer 설정
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

// ✅ Google Sheets API 설정
const SCOPES = ["https://www.googleapis.com/auth/spreadsheets"];

/**
 * Google Sheets API 클라이언트를 반환합니다.
 * @return {Promise<google.sheets_v4.Sheets>} sheets client
 */
async function getGoogleSheetsClient() {
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
 * @param {string} userId - 사용자 UID
 * @return {Promise<string>} 이메일 또는 "이메일 없음"
 */
async function getUserEmail(userId) {
  try {
    const userRecord = await admin.auth().getUser(userId);
    return userRecord.email || "이메일 없음";
  } catch (error) {
    console.error(
        `❌ Firebase에서 이메일 가져오기 실패: ${error.message}`,
    );
    return "이메일 없음";
  }
}

/* */


/**
 * 구글 시트의 Haruhancut 시트에 있는 유저 정보를 업데이트합니다.
 * @param {Object} userData - 사용자 데이터 객체
 */
async function updateUserInGoogleSheet(userData) {
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
        resource: {values: [values[userRowIndex]]},
      });
      console.log(
          `✅ 구글 시트 업데이트 완료: ${userData.uid}`,
      );
    } else {
      console.log(
          `⚠️ 업데이트할 유저를 찾을 수 없음: ${userData.uid}`,
      );
    }
  } catch (error) {
    console.error("❌ 구글 시트 업데이트 오류:", error);
  }
}

/**
 * 유저가 처음 닉네임을 설정할 때 구글 시트에 추가하고,
 * 관리자에게 이메일을 전송합니다.
 * @param {Object} userData - 사용자 데이터 객체
 */
async function addUserToGoogleSheet(userData) {
  try {
    const email = await getUserEmail(userData.uid);
    const sheets = await getGoogleSheetsClient();

    await sheets.spreadsheets.values.append({
      spreadsheetId: SHEET_ID,
      range: "Users!A:H",
      valueInputOption: "RAW",
      resource: {
        values: [
          [
            userData.nickname,
            userData.uid,
            userData.loginPlatform,
            // userData.gender,
            userData.birthdayDate,
            userData.registerDate,
            email,
            "",
          ],
        ],
      },
    });
    console.log(`✅ 새로운 유저 추가: ${userData.uid}`);

    const mailOptions = {
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
    };

    await transporter.sendMail(mailOptions);
    console.log("✅ 관리자에게 메일 전송 성공!");
  } catch (error) {
    console.error("❌ 유저 추가 오류:", error);
  }
}

/**
 * 유저 삭제를 감지하여 구글 시트의 Eummeyo 시트에
 * '탈퇴'로 표시합니다.
 * @param {string} userId - 사용자 UID
 */
async function markUserAsDeleted(userId) {
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
        resource: {values: [values[userRowIndex]]},
      });
      console.log(
          `🚨 유저 삭제 감지 - 탈퇴 처리 완료: ${userId}`,
      );
    } else {
      console.log(`⚠️ 삭제된 유저를 찾을 수 없음: ${userId}`);
    }
  } catch (error) {
    console.error("❌ 구글 시트 탈퇴 처리 오류:", error);
  }
}

// 트리거 설정

/**
 * 유저 데이터 업데이트 트리거
 * - 닉네임이 처음 생성되면 새 유저를 추가합니다.
 * - 이미 닉네임이 존재하면 유저 정보를 업데이트합니다.
 */
exports.addNewUserHaruhancut = onValueWritten(
    {
      region: "us-central1",
      ref: "/users/{uid}",
    },
    async (event) => {
      const beforeData = event.data.before.val();
      const afterData = event.data.after.val();

      if (!afterData) {
        return console.error("❌ 오류: 데이터 없음");
      }

      if ((!beforeData || !beforeData.nickname) &&
        afterData.nickname) {
        console.log(
            `📢 새로운 닉네임 생성 감지: ${afterData.nickname}`,
        );
        await addUserToGoogleSheet(afterData);
      } else {
        console.log(
            `ℹ️ 기존 유저 정보 업데이트 감지: ${afterData.uid}`,
        );
        await updateUserInGoogleSheet(afterData);
      }
    },
);

/**
 * 유저 데이터 삭제 트리거
 * - 유저 데이터 삭제 시 구글 시트에서 '탈퇴'로 업데이트합니다.
 */
exports.markUserDeletedInSheet = onValueDeleted(
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

// 게시글 업로드 알림
// haruhancut.js
// const BOT_SERVICE_ACCOUNT =
//   "haruhancut-kor-bot@haruhancut-kor-463605.iam.gserviceaccount.com";

// const BOT_SERVICE_ACCOUNT =
//   "haruhancut-kor-463605@appspot.gserviceaccount.com";
exports.notifyOnNewPost = onValueWritten(
    {
      region: "us-central1",
      // serviceAccount: BOT_SERVICE_ACCOUNT,
      ref: "/groups/{groupId}/postsByDate/{date}/{postId}",
    },
    async (event) => {
      const before = event.data.before.val();
      const after = event.data.after.val();
      // ❗ before가 있으면 “댓글 등으로 인한 업데이트”이므로 알림 안 보내기
      if (before) return;
      if (!after) return;

      const {groupId, postId} = event.params;
      const senderId = after.userId;
      const senderNickname = after.nickname;

      // 1) 그룹 멤버 UID만 꺼내기
      const membersSnap = await admin
          .database()
          .ref(`/groups/${groupId}/members`)
          .once("value");

      const tokens = [];
      for (const [uid] of Object.entries(membersSnap.val() || {})) {
        if (uid === senderId) continue;
        // 2) users/{uid}/fcmToken 경로에서 실제 토큰 조회
        const fcmSnap = await admin
            .database()
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

      // 3) 최대 500개씩 배치 전송
      const BATCH_SIZE = 500;
      let totalSuccess = 0; let totalFailure = 0;

      for (let i = 0; i < tokens.length; i += BATCH_SIZE) {
        const batch = tokens.slice(i, i + BATCH_SIZE);
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

        resp.responses.forEach((r, idx) => {
          if (!r.success) {
            console.error(`❌ [${batch[idx]}] 발송 실패:`, r.error);
          }
        });
      }

      console.log(
          `✅ 게시글 알림 완료: 성공 ${totalSuccess}건, 실패 ${totalFailure}건`,
      );
    },
);


exports.notifyOnNewComment = onValueWritten(
    {
      region: "us-central1",
      // serviceAccount: BOT_SERVICE_ACCOUNT,
      ref:
        "/groups/{groupId}/postsByDate/{date}/{postId}/comments/{commentId}",
    },
    async (event) => {
      const before = event.data.before.val();
      const after = event.data.after.val();
      // ❗ before가 있으면 “댓글 업데이트”이므로 알림 안 보내기
      if (before) return;
      if (!after) return;

      const {groupId, postId} = event.params;
      const senderId = after.userId;
      const senderNickname = after.nickname;

      // 그룹 멤버 조회
      const membersSnap = await admin
          .database()
          .ref(`/groups/${groupId}/members`)
          .once("value");

      const tokens = [];
      for (const [uid] of Object.entries(membersSnap.val() || {})) {
        if (uid === senderId) continue;
        const fcmSnap = await admin
            .database()
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

      // 배치 전송
      const BATCH_SIZE = 500;
      let totalSuccess = 0; let totalFailure = 0;

      for (let i = 0; i < tokens.length; i += BATCH_SIZE) {
        const batch = tokens.slice(i, i + BATCH_SIZE);
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

        resp.responses.forEach((r, idx) => {
          if (!r.success) {
            console.error(`❌ [${batch[idx]}] 발송 실패:`, r.error);
          }
        });
      }

      console.log(
          `✅ 댓글 알림 완료: 성공 ${totalSuccess}건, 실패 ${totalFailure}건`,
      );
    },
);
