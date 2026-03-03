//
//  NicknameSettingViewModel.swift
//  ProfileFeature
//
//  Created by 김동현 on 3/3/26.
//

import RxSwift
import RxCocoa
import Domain

final class NicknameEditViewModel: NicknameEditViewModelType {
    
    // MARK: - Coordinator Trigger
    var onPopButtonTapped: (() -> Void)?
    
    let disposBag = DisposeBag()
    var authUsecase: AuthUsecaseProtocol
    
    struct Input {
        let nicknameText: Observable<String>
        let endButtonTapped: Observable<Void>
    }
    
    struct Output {
        let isNicknameValid: Driver<Bool>
    }
    
    init(authUsecase: AuthUsecaseProtocol) {
        self.authUsecase = authUsecase
    }
    
    func transform(input: Input) -> Output {
        
        // 공백 제거된 닉네임
        let trimmedNickname = input.nicknameText
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines)}
            .share(replay: 1)
        
        // 유효성
        let isNicknameValid = trimmedNickname
            .map { !$0.isEmpty }    /// 유효성: 빈 값이 아닌가
            .distinctUntilChanged() /// 중복된 값은 무시하고 변경될 때만 다음 연산자 실행
            .asDriver(onErrorJustReturn: false)
        
        // MARK: - Coordinator
        input.endButtonTapped
            .withLatestFrom(trimmedNickname)
            .withUnretained(self)
            .flatMapLatest { owner, newNickname -> Observable<User> in
                return owner.authUsecase
                    .updateNicknameAndReloadSession(nickname: newNickname)
                    .asObservable()
                    .catch { _ in .empty() } // 추후 명시적인 에러 알림 추가
            }
            .observe(on: MainScheduler.instance)
            .bind(with: self, onNext: { owner, _ in
                owner.onPopButtonTapped?()
            })
            .disposed(by: disposBag)
            
        return Output(isNicknameValid: isNicknameValid)
    }
}
