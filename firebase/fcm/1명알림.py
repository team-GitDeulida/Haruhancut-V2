import argparse
from pathlib import Path
from typing import Any, Dict, Optional

import firebase_admin
from firebase_admin import credentials, db, messaging


SERVICE_ACCOUNT_PATH = Path(__file__).with_name(
    "haruhancut-kor-firebase-adminsdk-fbsvc-75227c5895.json"
)
DATABASE_URL = "https://haruhancut-kor-default-rtdb.firebaseio.com"

DEFAULT_TITLE = "🎉 하루한컷 1.1.2 업데이트"
DEFAULT_BODY = (
    "더 안정적이고 편리하게 사용할 수 있도록 개선했습니다.\n"
    "업데이트 후 새로운 하루를 기록해 보세요. 📸"
)


def initialize_firebase():
    try:
        return firebase_admin.get_app()
    except ValueError:
        if not SERVICE_ACCOUNT_PATH.is_file():
            raise FileNotFoundError(
                f"서비스 계정 파일을 찾을 수 없습니다: {SERVICE_ACCOUNT_PATH}"
            )

        cred = credentials.Certificate(str(SERVICE_ACCOUNT_PATH))
        return firebase_admin.initialize_app(
            cred,
            {"databaseURL": DATABASE_URL},
        )


def get_user(
    firebase_app,
    user_id: str,
) -> Optional[Dict[str, Any]]:
    user = db.reference(
        f"users/{user_id}",
        app=firebase_app,
    ).get()

    if not isinstance(user, dict):
        return None
    return user


def is_valid_fcm_token(token: Any) -> bool:
    return (
        isinstance(token, str)
        and token not in {"", "noFCM", "noToken"}
    )


def mask_token(token: str) -> str:
    if len(token) <= 16:
        return "***"
    return f"{token[:8]}...{token[-6:]}"


def send_fcm_notification(
    firebase_app,
    fcm_token: str,
    title: str,
    body: str,
    dry_run: bool,
) -> Optional[str]:
    message = messaging.Message(
        token=fcm_token,
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        apns=messaging.APNSConfig(
            headers={
                "apns-priority": "10",
                "apns-push-type": "alert",
            },
            payload=messaging.APNSPayload(
                aps=messaging.Aps(sound="default")
            ),
        ),
    )

    try:
        return messaging.send(
            message,
            dry_run=dry_run,
            app=firebase_app,
        )
    except messaging.UnregisteredError:
        print("❌ 만료되었거나 등록 해제된 FCM 토큰입니다.")
    except messaging.SenderIdMismatchError:
        print("❌ FCM 토큰과 Firebase 프로젝트가 일치하지 않습니다.")
    except messaging.ThirdPartyAuthError:
        print("❌ Firebase의 APNs 인증키가 유효하지 않습니다.")
    except Exception as error:
        print(
            f"❌ 전송 실패: {type(error).__name__}: {error}"
        )

    return None


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Realtime Database의 최신 토큰으로 한 명에게 알림을 전송합니다."
    )
    parser.add_argument(
        "user_id",
        help="알림을 받을 사용자의 Firebase UID",
    )
    parser.add_argument(
        "--send",
        action="store_true",
        help="실제로 알림을 전송합니다. 생략하면 검증만 수행합니다.",
    )
    parser.add_argument("--title", default=DEFAULT_TITLE)
    parser.add_argument("--body", default=DEFAULT_BODY)
    return parser.parse_args()


def main() -> None:
    args = parse_arguments()
    dry_run = not args.send
    firebase_app = initialize_firebase()
    user = get_user(firebase_app, args.user_id)

    if user is None:
        print("❌ 해당 userId를 찾을 수 없습니다.")
        raise SystemExit(1)

    nickname = str(user.get("nickname", "알 수 없는 사용자"))
    if not user.get("isPushEnabled", False):
        print(f"❌ {nickname} 사용자는 알림 설정이 꺼져 있습니다.")
        raise SystemExit(1)

    token = user.get("fcmToken")
    if not is_valid_fcm_token(token):
        print("❌ 유효한 FCM 토큰이 없습니다.")
        raise SystemExit(1)

    mode = "검증" if dry_run else "전송"
    print(f"➡️ 사용자: {nickname}")
    print(f"➡️ 최신 FCM 토큰: {mask_token(token)}")
    print(f"➡️ 알림 {mode} 중...")

    response = send_fcm_notification(
        firebase_app=firebase_app,
        fcm_token=token,
        title=args.title,
        body=args.body,
        dry_run=dry_run,
    )

    if response is None:
        raise SystemExit(1)

    print(f"✅ {mode} 성공: {response}")


if __name__ == "__main__":
    main()
