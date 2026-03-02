//
//  SettingViewModel.swift
//  ProfileFeature
//
//  Created by 김동현 on 3/2/26.
//

import RxSwift
import Domain
import Core
import RxCocoa
import ProfileFeatureInterface

final class SettingViewModel: SettingViewModelType {
    
    // MARK: - Coordinator Trigger
    var onLogoutTapped: (() -> Void)?
    
    private let disposeBag = DisposeBag()
    private let authUsecase: AuthUsecaseProtocol
    @Dependency var userSession: UserSession
    @Dependency var groupSession: GroupSession
    
    struct Input {
        /// 로그아웃 버튼 이벤트
        let logoutTapped: Observable<Void>
        
        /// 알림 토글 이벤트
        let notificationToggleTapped : Observable<Bool>
    }
    
    struct Output {
        // 알림 토글 상태 결과
        let notificationState: Driver<Bool>
    }
    
    init(authUsecase: AuthUsecaseProtocol) {
        self.authUsecase = authUsecase
    }
    
    func transform(input: Input) -> Output {
        
        // MARK: - Coordinator
        input.logoutTapped// output안줄거다 owner.authUsecase.signOut()으로 로그아웃 정상처리된다 이대로유지
            .withUnretained(self)
            .flatMapLatest { owner, _ in
                owner.authUsecase.signOut()
            }
            .subscribe()
            .disposed(by: disposeBag)
        
        // 최초 토글 상태(현재 세션 값)
        let initialState = Observable.just(userSession.session?.isPushEnabled ?? false)
        
        // 토글 탭 & 로직 처리 후 결과
        let afterState = input.notificationToggleTapped
            .withUnretained(self)
            .flatMapLatest { owner, isOn -> Observable<Bool> in
                guard let sessionUser = owner.userSession.session else {
                    return Observable.just(false)
                }
                
                // 1. 기존 값 저장
                let beforeIsPushEnabled = sessionUser.isPushEnabled
                
                // 2. 세션 먼저 변경(낙관적 업데이트)
                owner.userSession.update(\.isPushEnabled, isOn)
                
                // 3. 서버 반영
                var updatedUser = sessionUser
                updatedUser.isPushEnabled = isOn
                
                return owner.authUsecase.updateUser(user: updatedUser)
                    .map(\.isPushEnabled)
                    .asObservable()
                    .catch { error in
                        // 4. 실패 시 롤백
                        owner.userSession.update(\.isPushEnabled, beforeIsPushEnabled)
                        return Observable.just(beforeIsPushEnabled)
                    }
            }
  
        
        // merge
        let notificationState = Observable
            .merge(initialState, afterState)
            .asDriver(onErrorJustReturn: false)

        return Output(notificationState: notificationState)
    }
}
