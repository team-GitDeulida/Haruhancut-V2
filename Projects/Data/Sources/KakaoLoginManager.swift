//
//  Empty.swift
//  Core
//
//  Created by 김동현 on 
//

import RxSwift
import KakaoSDKUser
import RxKakaoSDKUser
import Core
import Foundation
import KakaoSDKAuth

/*
 Single<String>
 - 이 타입의 의미
 - 성공 → onSuccess(String)
 - 실패 → onError(Error)
 - ❌ 실패를 값으로 표현할 수 없음 의도
 */
public protocol KakaoLoginManagerProtocol {
    func login() -> Single<String>
}

public final class KakaoLoginManager: KakaoLoginManagerProtocol {
    
    public init() {}
    
//    public func login() -> Single<String> {
//        Logger.d("login 1-1")
//        
//        // 카카오 앱 설치되어 있으면 카카오 앱으로 로그인
//        let loginSingle = UserApi.isKakaoTalkLoginAvailable()
//        ? UserApi.shared.rx.loginWithKakaoTalk().asSingle()
//        : UserApi.shared.rx.loginWithKakaoAccount().asSingle()
//        
//        return loginSingle
//            // idToken만 뽑기
//            .flatMap { token in
//                Logger.d("login 1-2")
//                guard let idToken = token.idToken else {
//                    return .error(LoginError.noTokenKakao)
//                }
//                Logger.d("login 1-3: \(idToken)")
//                return .just(idToken)
//            }
//            .catch { error in
//                return .error(LoginError.sdkKakao(error))
//            }
//    }
    
    public func login() -> Single<String> {
        return Single<String>.create { observer in

            let completion: (OAuthToken?, Error?) -> Void = { token, error in
                if let error {
                    observer(.failure(LoginError.sdkKakao(error)))
                    return
                }

                guard let idToken = token?.idToken else {
                    observer(.failure(LoginError.noTokenKakao))
                    return
                }

                observer(.success(idToken))
            }

            if UserApi.isKakaoTalkLoginAvailable() {
                UserApi.shared.loginWithKakaoTalk(completion: completion)
            } else {
                UserApi.shared.loginWithKakaoAccount(completion: completion)
            }

            return Disposables.create()
        }
    }
}
