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
        let loginError: Driver<LoginError>
        // let loginResult: Driver<Result<SocialAuthPayload, LoginError>>
    }
    
    // MARK: - Init
    public init(signInUsecase: SignInUsecaseProtocol) {
        self.signInUsecase = signInUsecase
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
            .flatMapLatest { vm, platform -> Observable<Void> in
                self.loginFlow(platform: platform)
                    // 로그인 플로우 중 에러가 발생하면
                    // Result로 감싸지 않고 Rx 에러 스트림으로 처리
                    .do(onError: { error in
                        if let loginError = error as? LoginError {
                            errorRelay.accept(loginError)
                        }
                    })
                    // 에러는 UI로 전달했으므로 스트림은 종료시키지 않음
                    .catchAndReturn(())
            }
            .subscribe()
            .disposed(by: disposeBag)
        
        return Output(loginError: errorRelay.asDriver(onErrorDriveWith: .empty()))
    }
}

private extension SignInViewModel {
    /// 전체 로그인 시나리오
    ///
    /// 1. 소셜 로그인 (Kakao / Apple)
    /// 2. Firebase 인증 (성공 여부만 중요)
    /// 3. 기존 유저 / 신규 유저 분기
    func loginFlow(platform: User.LoginPlatform) -> Observable<Void> {
        signInUsecase
            // 1. 선택된 플랫폼으로 "소셜 로그인" 요청
            //    - kakao → kakao token
            //    - apple → idToken + authorizationCode
            .signIn(with: platform)
            
            // 2. 인증 → 유저 판별 시나리오
            .flatMap { payload in
                self.authenticate(payload: payload)
                    .andThen(self.resolveUser(payload: payload))
            }
            .asObservable()
    }
    
    /// Firebase 인증
    ///
    /// - 인증 결과 값은 필요 없고
    /// - 성공 / 실패 여부만 중요
    /// → Completable 로 표현
    func authenticate(payload: SocialAuthPayload) -> Completable {
        switch payload {
        case .kakao(let token):
            return signInUsecase.authenticateUser(prividerID: "kakao",
                                                  idToken: token,
                                                  rawNonce: nil)
            .asCompletable()
        case .apple(let idToken, let rawNonce):
            print("디버깅: idToken: \(idToken), rawNonce:\(rawNonce)")
            return signInUsecase.authenticateUser(prividerID: "apple",
                                                  idToken: idToken,
                                                  rawNonce: rawNonce)
            .asCompletable()
        }
    }
    
    /// 기존 유저 / 신규 유저 판별
    ///
    /// - 기존 유저: 홈으로 이동
    /// - 신규 유저: 온보딩으로 이동
    /// - 분기 결과는 side-effect로만 처리
    func resolveUser(payload: SocialAuthPayload) -> Single<Void> {
        signInUsecase.fetchUserInfo()
            .do(onSuccess: { [weak self] _ in
                // 기존 유저
                self?.onSignInSuccess?()
            })
            .catch { [weak self] error in
                guard let self else { return .error(error) }

                if case LoginError.noUser = error {
                    // 신규 유저
                    self.onFirstSignInSuccess?(payload.platform)
                }

                return .error(error)
            }
            .map { _ in () }
    }
}
