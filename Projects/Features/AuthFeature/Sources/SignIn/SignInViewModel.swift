//
//  SignInViewModel.swift
//  AuthFeatureInterface
//
//  Created by 김동현 on 1/15/26.
//

import AuthFeatureInterface
import Domain
import Core
import RxSwift
import RxCocoa

final class SignInViewModel: SignInViewModelType {
    let disposeBag = DisposeBag()
    
    // MARK: - Properties
    private let signInUsecase: SignInUsecaseProtocol

    // MARK: - Coordinate Trigger
    var onSignInSuccess: (() -> Void)?
    
    // MARK: - Inputs
    public struct Input {
        let kakaoLoginButtonTapped: Driver<Void>
        let appleLoginButtonTapped: Driver<Void>
    }
    
    // MARK: - Outputs
    public struct Output {
        let loginResult: Driver<Result<Void, LoginError>>
    }
    
    // MARK: - Init
    public init(signInUsecase: SignInUsecaseProtocol) {
        self.signInUsecase = signInUsecase
    }
}

extension SignInViewModel {
    func transform(input: Input) -> Output {
        
        let kakaoResult = input.kakaoLoginButtonTapped.map { Result<Void, LoginError>.success(()) }
        let appleResult = input.appleLoginButtonTapped.map { Result<Void, LoginError>.success(()) }
        
        let loginResult = Driver.merge(kakaoResult, appleResult)
            // side effect
            .do(onNext: { [weak self] result in
                if case .success = result {
                    self?.onSignInSuccess?()
                }
            })
        
        return Output(loginResult: loginResult)
        
        // return Output(loginResult: Driver.empty())
        // return Output(loginResult: Driver.just(.success(())))
    }
}
