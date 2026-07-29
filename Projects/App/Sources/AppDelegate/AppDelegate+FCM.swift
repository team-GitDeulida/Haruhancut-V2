//
//  AppDelegate+FCM.swift
//  App
//
//  Created by 김동현 on 2/23/26.
//
/*
 didRegisterForRemoteNotificationsWithDeviceToken
 - APNs 등록 성공시(애플 서버가 이 기기 푸시 허용시) 호출됨
 - 앱 처음 설치 후 푸쉬 권한 허용
 - 앱 재설치
 - 디바이스 변경
 - 앱이 APNs 등록 요청시
 
 didReceiveRegistrationToken
 - FCM 토큰이 새로 발급되거나 갱신될 때 자동 호출
 - 앱 최초 실행
 - 재설치
 - 토큰 만료
 - FCM 내부 정책 변경
 - APNs 토큰 변경
 - 앱 업데이트 등
 
 willPresent
 - 앱이 켜져 있는 상태(포그라운드)에서 푸시 도착
 
 https://burgerkinghero.tistory.com/1
 */
import UIKit
import UserNotifications
import FirebaseMessaging
import Domain
import Core

extension AppDelegate {

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
        Logger.d("APNs device token 등록 완료")
        syncFcmTokenIfNeeded(source: "APNs 등록")
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Logger.e("APNs 등록 실패: \(error.localizedDescription)")
    }

    private func syncFcmTokenIfNeeded(source: String) {
        let authUsecase = DIContainer.shared.resolve(AuthUsecaseProtocol.self)
        _ = authUsecase.syncFcmIfNeeded()
            .subscribe(
                onSuccess: {
                    Logger.d("\(source) 후 FCM 토큰 동기화 완료")
                },
                onFailure: { error in
                    Logger.e(
                        "\(source) 후 FCM 토큰 동기화 실패: \(error.localizedDescription)"
                    )
                }
            )
    }
}

extension AppDelegate: MessagingDelegate {

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else {
            Logger.w("FCM registration token이 없습니다.")
            return
        }

        let store = DIContainer.shared.resolve(FCMTokenStore.self)
        store.latestToken = token
        syncFcmTokenIfNeeded(source: "FCM 토큰 수신")
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        Logger.d("포그라운드 알림 수신")
        return [.list, .banner, .sound]
    }
}
