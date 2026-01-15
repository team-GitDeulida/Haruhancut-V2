//
//  StubAuthRepositoryImpl.swift
//  AuthFeatureDemo
//
//  Created by 김동현 on 1/13/26.
//

import Domain
import RxSwift
import Core

public final class StubSignInRepositoryImpl: SignInRepositoryProtocol {
    public func loginWithKakao() -> Observable<Result<String, LoginError>> {
        return .just(.success("mockToken"))
    }
}
