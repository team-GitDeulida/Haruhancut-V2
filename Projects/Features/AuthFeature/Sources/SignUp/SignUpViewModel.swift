//
//  SignUpViewModel.swift
//  AuthFeature
//
//  Created by 김동현 on 1/16/26.
//

import UIKit
import AuthFeatureInterface
import RxSwift
import RxCocoa
import Domain
import FirebaseMessaging
import Core

final class SignUpViewModel: SignUpViewModelType {
    
    private let disposeBag = DisposeBag()
    
    // MARK: - Properties
    private let signInUsecase: SignInUsecaseProtocol
    
    // ViewModel 내부
    private let stepRelay = BehaviorRelay<Step>(value: .nickname)
    private let nicknameRelay = BehaviorRelay<String>(value: "")
    private let birthdayRelay = BehaviorRelay<Date>(value: Date())
    private let profileImageRelay = BehaviorRelay<UIImage?>(value: nil)

    // registerUser Builder
    let userBuilder: UserBuilder
    
    // trigger
    var onSignUpSuccess: (() -> Void)?
    
    enum Step {
        case nickname
        case birthday
        case profile
        case finish
    }
        
    // View에서 발생한 이벤트
    struct Input {
        // nickname
        let nicknameText: Observable<String>   /// 닉네임 입력 텍스트
        
        // birthday
        let birthdatDate: Observable<Date>     /// 생일 입력 picker
        
        // profile
        let profileImage: Observable<UIImage?> /// 프로필 이미지
        
        // 공통
        let nextButtonTapped: Observable<Void> /// 다음 버튼 탭
    }
    
    // View가 그리기 위한 결과
    struct Output {
        // nickname
        let isNicknameValid: Driver<Bool> /// 유효성
    
        // 공통
        let step: Driver<Step>       /// 현재 회원가입 단계
        let nickname: Driver<String> /// 확정된 닉네임
    }
    
    init(signInUsecase: SignInUsecaseProtocol,
         loginPlatform: User.LoginPlatform
    ) {
        self.signInUsecase = signInUsecase
        self.userBuilder = UserBuilder(loginPlatform: loginPlatform)
    }
}

extension SignUpViewModel {
    func transform(input: Input) -> Output {
        
        // 닉네임 유효성
        let isNicknameValid = input.nicknameText
            // 앞뒤 공백 제거 후, 한 글자라도 있으면 true
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).count != 0 }
            .distinctUntilChanged()             // 중복된 값은 무시하고 변경될 때만 아래로 전달
            .asDriver(onErrorJustReturn: false) // 에러 발생 시에도 false를 대신 방출
        
        input.nicknameText
            .bind(to: nicknameRelay)
            .disposed(by: disposeBag)
        
        input.birthdatDate
            .bind(to: birthdayRelay)
            .disposed(by: disposeBag)
        
        input.profileImage
            .bind(to: profileImageRelay)
            .disposed(by: disposeBag)
        
        // withLatestFrom: 이벤트 발생 시 그 순간의 최신 값을 가져온다
        // combineLatest:  여러 값 중 하나라도 변경되면 그 시점의 모든 최신 값을 한 묶음으로 만들어 방출한다
        input.nextButtonTapped
            .withLatestFrom(Observable.combineLatest(stepRelay,
                                                     nicknameRelay,
                                                     birthdayRelay,
                                                     profileImageRelay))
            .flatMapLatest { [weak self] step, nickname, birtyday, profile in
                guard let self = self else { return Observable<Step>.empty() }
                switch step {
                case .nickname:
                    print("nickname 확정:", nickname)
                    self.userBuilder.withNickname(nickname)
                    return .just(.birthday)

                case .birthday:
                    print("birthday 확정:", birtyday)
                    self.userBuilder.withBirthday(birtyday)
                    return .just(.profile)

                case .profile:
                    // print("profile 확정:", profile ?? "이미지 없음")
                    if let profile = profile {
                        self.userBuilder.withProfileImage(profile)
                    }
                    
                    let user = self.userBuilder.build()
                    
                    // 1) FCM 토큰 발급
                    return self.generateFcmToken()
                        
                        // 2) User 모델에 토큰 저장
                        .flatMapLatest { token -> Observable<User> in
                            var userWithToken = user
                            userWithToken.fcmToken = token
                            return .just(userWithToken)
                        }
                    
                        // 3) 회원가입 + 이미지 업로드 로직(이미지 존재 시)
                        .flatMapLatest { userWithToken -> Observable<Result<Void, LoginError>> in
                            self.registerUserWithProfileIfNeeded(user: userWithToken, image: profile)
                        }
                    
                        // 4) 회원가입 성공시 화면 전환
                        .do(onNext: { [weak self] result in
                            if case .success = result {
                                self?.onSignUpSuccess?()
                            }
                        })
                        .map { _ in Step.finish }
                    

                case .finish:
                    return .just(.finish)
                }
            }
            .bind(to: stepRelay)
            .disposed(by: disposeBag)

        
        return Output(isNicknameValid: isNicknameValid.asDriver(),
                      step: stepRelay.asDriver(),
                      nickname: nicknameRelay.asDriver())
    }
}

// MARK: - Usecase Wrapper
extension SignUpViewModel {
    
    // FCM 토큰 발급
    private func generateFcmToken() -> Observable<String> {
        return Observable.create { observer in
            Messaging.messaging().token { token, error in
                if let error = error {
                    print("⚠️ FCM 토큰 발급 실패: \(error.localizedDescription)")
                    print("⚠️ FCM 토큰을 받을 수 없는 기기라서 넘어갑니다.")
                    observer.onNext("noFCM")
                    observer.onCompleted()
                } else if let token = token {
                    observer.onNext(token)
                    observer.onCompleted()
                } else {
                    observer.onError(NSError(domain: "FCMToken", code: -1,
                                             userInfo: [NSLocalizedDescriptionKey: "토큰이 없습니다"]))
                }
            }
            
            return Disposables.create()
        }
    }
    
    // legacy
    private func registerUser(user: User) -> Observable<Result<Void, LoginError>> {
        signInUsecase
            .registerUserToRealtimeDatabase(user: user) // Result<User, LoginError>
            .map { $0.mapToVoid() }
    }
    
    private func registerUserWithProfileIfNeeded(user: User, image: UIImage?) -> Observable<Result<Void, LoginError>> {
        signInUsecase
            .registerUserToRealtimeDatabase(user: user) // Result<User, LoginError>
            .flatMapLatest { result -> Observable<Result<Void, LoginError>> in
                guard case .success(let registerUser) = result else {
                    return .just(result.mapToVoid())
                }
                
                // 이미지가 없으면 종료
                guard let image = image else { return .just(.success(())) }
                
                // 이미지 업로드
                return self.signInUsecase
                    .uploadImage(user: registerUser, image: image)
                    .flatMapLatest { uploadResult in
                        switch uploadResult {
                        case .success(let url):
                            var updated = registerUser
                            updated.profileImageURL = url.absoluteString
                            
                            return self.signInUsecase
                                .updateUser(user: updated)
                                .map { $0.mapToVoid() }
                        case .failure(let error):
                            return .just(.failure(error))
                        }
                    }
            }
    }
}

