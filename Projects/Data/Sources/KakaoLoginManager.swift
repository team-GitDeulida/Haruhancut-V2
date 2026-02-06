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
    
    public func login() -> Single<String> {
        let loginSingle = UserApi.isKakaoTalkLoginAvailable()
        ? UserApi.shared.rx.loginWithKakaoTalk().asSingle()
        : UserApi.shared.rx.loginWithKakaoAccount().asSingle()
        
        return loginSingle
            .flatMap { token in
                guard let idToken = token.idToken else {
                    return .error(LoginError.noTokenKakao)
                }
                return .just(idToken)
            }
            .catch { error in
                return .error(LoginError.sdkKakao(error))
            }
    }
}
