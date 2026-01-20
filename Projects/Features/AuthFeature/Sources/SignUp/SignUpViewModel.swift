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

final class SignUpViewModel: SignUpViewModelType {
    
    private let disposeBag = DisposeBag()
    
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
    
    init(loginPlatform: User.LoginPlatform) {
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
            .map { step, nickname, birtyday, profile in
                switch step {
                case .nickname:
                    print("nickname 확정:", nickname)
                    self.userBuilder.withNickname(nickname)
                    return .birthday

                case .birthday:
                    print("birthday 확정:", birtyday)
                    self.userBuilder.withBirthday(birtyday)
                    return .profile

                case .profile:
                    print("profile 확정:", profile ?? "이미지 없음")
                    if let profile = profile {
                        self.userBuilder.withProfileImage(profile)
                    }
                    self.userBuilder.build()
                    self.onSignUpSuccess?()
                    return .finish

                case .finish:
                    return .finish
                }
            }
            .bind(to: stepRelay)
            .disposed(by: disposeBag)

        
        return Output(isNicknameValid: isNicknameValid.asDriver(),
                      step: stepRelay.asDriver(),
                      nickname: nicknameRelay.asDriver())
    }
}
