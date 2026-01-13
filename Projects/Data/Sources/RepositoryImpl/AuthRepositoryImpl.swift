//
//  AuthRepositoryImpl.swift
//  Domain
//
//  Created by 김동현 on 1/12/26.
//

import Domain
import RxSwift
import Core

public final class AuthRepositoryImpl: AuthRepositoryProtocol {
    
    private let kakaoLoginManager: KakaoLoginManager
    
    public init(kakaoLoginManager: KakaoLoginManager) {
        self.kakaoLoginManager = kakaoLoginManager
    }
    
    public func loginWithKakao() -> Observable<Result<String, LoginError>> {
        return kakaoLoginManager.login()
    }
}

public final class StubAuthRepositoryImpl: AuthRepositoryProtocol {
    
    public init() {}
    
    public func loginWithKakao() -> Observable<Result<String, LoginError>> {
        return .just(.success("mockToken"))
    }
}
