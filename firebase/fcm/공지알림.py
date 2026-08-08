import argparse
from pathlib import Path
from typing import Any, List, Optional, Tuple

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

UserTarget = Tuple[str, str]


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


def mask_token(token: str) -> str:
    if len(token) <= 16:
        return "***"
    return f"{token[:8]}...{token[-6:]}"


def is_valid_fcm_token(token: Any) -> bool:
    return (
        isinstance(token, str)
        and token not in {"", "noFCM", "noToken"}
    )


def get_users(firebase_app) -> List[UserTarget]:
    users = db.reference("users", app=firebase_app).get()
    if not isinstance(users, dict):
        return []

    targets: List[UserTarget] = []
    disabled_count = 0
    invalid_token_count = 0

    for user_info in users.values():
        if not isinstance(user_info, dict):
            continue

        if not user_info.get("isPushEnabled", False):
            disabled_count += 1
            continue

        token = user_info.get("fcmToken")
        if not is_valid_fcm_token(token):
            invalid_token_count += 1
            continue

        nickname = str(
            user_info.get("nickname", "알 수 없는 사용자")
        )
        targets.append((nickname, token))

    targets.sort(key=lambda target: target[0])

    print("✅ 공지 발송 대상")
    print(f"   발송 대상: {len(targets)}명")
    print(f"   알림 비활성화: {disabled_count}명")
    print(f"   유효한 토큰 없음: {invalid_token_count}명")

    for nickname, token in targets:
        print(f"👤 {nickname} - 🔑 {mask_token(token)}")

    return targets


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
        description="알림 수신에 동의한 전체 사용자에게 공지를 전송합니다."
    )
    parser.add_argument(
        "--send",
        action="store_true",
        help="실제로 공지를 전송합니다. 생략하면 검증만 수행합니다.",
    )
    parser.add_argument("--title", default=DEFAULT_TITLE)
    parser.add_argument("--body", default=DEFAULT_BODY)
    return parser.parse_args()


def main() -> None:
    args = parse_arguments()
    dry_run = not args.send
    firebase_app = initialize_firebase()
    targets = get_users(firebase_app)

    if not targets:
        print("❌ 공지를 전송할 사용자가 없습니다.")
        raise SystemExit(1)

    print()
    print(f"제목: {args.title}")
    print(f"본문: {args.body}")

    if dry_run:
        print("🧪 검증 모드입니다. 실제 알림은 전송되지 않습니다.")
    else:
        confirmation = input(
            f"⚠️ {len(targets)}명에게 전송합니다. "
            "계속하려면 SEND를 입력하세요: "
        )
        if confirmation != "SEND":
            print("⛔ 공지 전송을 취소했습니다.")
            return

    success_count = 0
    failure_count = 0

    for index, (nickname, token) in enumerate(targets, start=1):
        mode = "검증" if dry_run else "전송"
        print(
            f"➡️ [{index}/{len(targets)}] "
            f"{nickname} {mode} 중..."
        )

        response = send_fcm_notification(
            firebase_app=firebase_app,
            fcm_token=token,
            title=args.title,
            body=args.body,
            dry_run=dry_run,
        )

        if response is None:
            failure_count += 1
        else:
            success_count += 1
            print(f"✅ {mode} 성공: {response}")

    print()
    print(f"✅ 성공: {success_count}명")
    print(f"❌ 실패: {failure_count}명")

    if failure_count:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
