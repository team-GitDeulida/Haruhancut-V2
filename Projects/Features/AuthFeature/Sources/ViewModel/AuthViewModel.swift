//
//  SignInViewController.swift
//  AuthFeature
//
//  Created by 김동현 on 1/12/26.
//

import UIKit
import AuthFeatureInterface
import Domain
import ThirdPartyLibs
import Core

final class AuthViewModel: AuthViewModelType {
    
    // MARK: - Properties
    private var disposeBag = DisposeBag()
    private let useCase: AuthUsecaseProtocol
    @Dependency private var authRepository: AuthRepositoryProtocol
    
    // MARK: - Coordinator
    var onAuthCompleted: (() -> Void)?
    
    // MARK: - Input
    public struct Input {
        let kakaoButtonTapped: Observable<Void>
        let appleButtonTapped: Observable<Void>
    }
    
    // MARK: - Output
    public struct Output {
        let loginResult: Driver<Result<Void, Error>>
    }
    
//    public func transform(input: Input) -> Output {
//        // MARK: - 카카오 로그인
//        let kakaoResult = input.kakaoButtonTapped
//            // 1. 카카오 토근 발급
//            .flatMapLatest { [weak self] _ -> Observable<Result<String, LoginError>> in
//                guard let self = self else { return .empty() }
//                return authRepository.loginWithKakao()
//            }
//   
//        
//        let mergedResult = Observable.merge(kakaoResult, kakaoResult)
//            .asDriver(onErrorJustReturn: .failure(.signUpError))
//        
//        return Output(loginResult: mergedResult)
//    }
    
    public init(useCase: AuthUsecaseProtocol) {
        self.useCase = useCase
    }
}

final class StubAuthViewModel: AuthViewModelType {
    var onAuthCompleted: (() -> Void)?
    
}
