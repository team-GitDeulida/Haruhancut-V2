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
    var onFirstSignInSuccess: ((User.LoginPlatform) -> Void)?
    
    // MARK: - Inputs
    public struct Input {
        let kakaoLoginButtonTapped: Observable<Void>
        let appleLoginButtonTapped: Observable<Void>
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
        
        // 로그인 플랫폼 선택
        let kakaoPlatform = input.kakaoLoginButtonTapped.map { User.LoginPlatform.kakao }
        let applePlatform = input.appleLoginButtonTapped.map { User.LoginPlatform.apple }
        let selectedPlatform = Observable.merge(kakaoPlatform, applePlatform)
        
        // 선택된 플랫폼으로 로그인 시도
        let loginResult = selectedPlatform
            .flatMapLatest { [weak self] platform in
                guard let self = self else {
                    return Observable<(User.LoginPlatform, Result<Void, LoginError>)>.empty()
                }
                
                // 소셜 로그인
                return signInUsecase
                    .signIn(with: platform)
                    .map { result in
                        (platform, result)
                    }
            }
            
            // side effect(결과에 따라 플로우 분기)
            .do(onNext: { [weak self] platform, result in
                
                // 기존 유저 로그인
                if case .success = result {
                    self?.onSignInSuccess?()
                }
                
                // 신규 유저 로그인
                if case .failure(.noUser) = result {
                    self?.onFirstSignInSuccess?(platform)
                }
            })
            .map { _, result in result }
            .asDriver(onErrorJustReturn: .failure(.signUpError))
        
        return Output(loginResult: loginResult)
        
        // return Output(loginResult: Driver.empty())
        // return Output(loginResult: Driver.just(.success(())))
    }
}
