//
//  Empty.swift
//  Core
//
//  Created by 김동현 on 
//

import RxSwift
import KakaoSDKUser
import RxKakaoSDKUser

public final class KakaoLoginManager {
    
    public init() {}
    
    public func login() -> Observable<Result<String, LoginError>> {
        let loginObservable = UserApi.isKakaoTalkLoginAvailable()
        ? UserApi.shared.rx.loginWithKakaoTalk()
        : UserApi.shared.rx.loginWithKakaoAccount()
        
        return loginObservable
            .map { token in
                guard let idToken = token.idToken else {
                    return .failure(.noTokenKakao)
                }
                return .success(idToken)
            }
            .catch { error in
                return .just(.failure(.sdkKakao(error)))
            }
    }
}
