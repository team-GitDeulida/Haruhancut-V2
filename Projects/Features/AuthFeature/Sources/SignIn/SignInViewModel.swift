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
    private let authUsecase: AuthUsecaseProtocol

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
        let loginError: Driver<LoginError>
        // let loginResult: Driver<Result<SocialAuthPayload, LoginError>>
    }
    
    // MARK: - Init
    public init(authUsecase: AuthUsecaseProtocol) {
        self.authUsecase = authUsecase
    }
}

extension SignInViewModel {
    func transform(input: Input) -> Output {
        
        // 로그인 플랫폼 선택 이벤트로 변환
        let kakaoPlatform = input.kakaoLoginButtonTapped.map { User.LoginPlatform.kakao }
        let applePlatform = input.appleLoginButtonTapped.map { User.LoginPlatform.apple }
        let selectedPlatform = Observable.merge(kakaoPlatform, applePlatform)
        
        // 로그인 과정에서 발생한 에러를 UI로 전달하기 위한 Relay
        let errorRelay = PublishRelay<LoginError>()
        
        // 로그인 플로우 실행
        selectedPlatform
            .withUnretained(self)
            .flatMap { vm, platform -> Observable<Void> in
                self.authUsecase.signIn(platform: platform)
                    .asObservable()
                    .do(onNext: { result in
                        switch result {
                        case .existingUser:
                            self.onSignInSuccess?()
                        case .newUser(let platform):
                            self.onFirstSignInSuccess?(platform)
                        }
                    })
                    .mapToVoid() // Observable<SignInResult> -> Observable<Void>
                    .catch { error in
                        if let loginError = error as? LoginError {
                            errorRelay.accept(loginError)
                        }
                        return .empty()
                    }
            }
            .subscribe()
            .disposed(by: disposeBag)
        
        return Output(loginError: errorRelay.asDriver(onErrorDriveWith: .empty()))
    }
}
