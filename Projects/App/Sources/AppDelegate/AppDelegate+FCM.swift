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
import Foundation
import FirebaseMessaging
import Domain
import Core

extension AppDelegate: MessagingDelegate {

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        let store = DIContainer.shared.resolve(FCMTokenStore.self)
        store.latestToken = token
        
        let authUsecase = DIContainer.shared.resolve(AuthUsecaseProtocol.self)
        _ = authUsecase.syncFcmIfNeeded().subscribe()
    }
}
