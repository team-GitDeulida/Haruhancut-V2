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
        let loginResult: Driver<Result<SocialAuthPayload, LoginError>>
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
                    return Observable<Result<SocialAuthPayload, LoginError>>.empty()
                }
                
                // 소셜 로그인 플로우
                return self.loginFlow(platform: platform)
            }
            .asDriver(onErrorJustReturn: .failure(.signUpError))
        
        return Output(loginResult: loginResult)
        
        // return Output(loginResult: Driver.empty())
        // return Output(loginResult: Driver.just(.success(())))
    }
}

private extension SignInViewModel {
    // 소셜 로그인 -> firebase 인증 -> 유저 판별
    func loginFlow(platform: User.LoginPlatform) -> Observable<Result<SocialAuthPayload, LoginError>> {
        signInUsecase
            // 1. 선택된 플랫폼으로 "소셜 로그인" 요청
            //    - kakao → kakao token
            //    - apple → idToken + authorizationCode
            .signIn(with: platform)
            
            // 2. 소셜 로그인 결과를 다음 단계로 연결
            .flatMapLatest { [weak self] result in
                guard let self = self else {
                    return Observable<Result<SocialAuthPayload, LoginError>>.empty()
                }
                
                switch result {
                case .failure(let error):
                    // 그대로 실패를 UI까지 전달
                    return .just(.failure(error))
                    
                case .success(let payload):
                    // Firebase 인증 + 기존/신규 유저 판별
                    return self.authenticateAndResolveUser(payload: payload)
                }
            }
    }
    
    // firebase 인증 후 기존 / 신규 유저 판별
    func authenticateAndResolveUser(payload: SocialAuthPayload) -> Observable<Result<SocialAuthPayload, LoginError>> {
        return authenticate(payload: payload)
            // authenticate(...) 결과: Observable<Result<Void, LoginError>>
            .flatMapLatest { [weak self] authResult in
                guard let self = self else {
                    return Observable<Result<SocialAuthPayload, LoginError>>.empty()
                }
                
                switch authResult {
                case .failure(let error):
                    print("Firebase Auth 실패: \(error)")
                    return .just(.failure(error))
                    
                case .success:
                    // 인증 성공
                    // 이제 "이 사람이 기존 유저인지?" 조회 함수 호출
                    return self.resolveUser(payload: payload)
                }
            }
    }
    
    // payload -> firebase auth 파라미터 변환
    func authenticate(payload: SocialAuthPayload) -> Observable<Result<Void, LoginError>> {
        switch payload {
        case .kakao(let token):
            return signInUsecase.authenticateUser(prividerID: "kakao",
                                                  idToken: token,
                                                  rawNonce: nil)
        case .apple(let idToken, let rawNonce):
            print("디버깅: idToken: \(idToken), rawNonce:\(rawNonce)")
            return signInUsecase.authenticateUser(prividerID: "apple",
                                                  idToken: idToken,
                                                  rawNonce: rawNonce)
        }
    }
    
    // 기존 유저 / 신규 유저 분기
    func resolveUser(payload: SocialAuthPayload) -> Observable<Result<SocialAuthPayload, LoginError>> {
        let userStream = signInUsecase
            // Firebase Realtime DB에서 내 정보 조회
            .fetchUserInfo()
        
        let resolvedStream = userStream
            .map { [weak self] user in
                guard let self = self else {
                    return Result<SocialAuthPayload, LoginError>.failure(.signUpError)
                }
                
                if user != nil {
                    // 기존 유저
                    print("기존 유저")
                    self.onSignInSuccess?()
                    return .success(payload)
                } else {
                    // 신규 유저
                    print("신규 유저")
                    self.onFirstSignInSuccess?(payload.platform)
                    return .failure(.noUser)
                }
            }
        
        return resolvedStream
    }
}
