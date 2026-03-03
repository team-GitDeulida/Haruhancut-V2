//
//  SettingViewModel.swift
//  ProfileFeature
//
//  Created by 김동현 on 3/2/26.
//

/*
 사용자가 토글을 누름
         ↓
 toggleFlow (핵심 로직)
         ↓
 (최종상태, alert필요여부)
         ↓
 1️⃣ UI 상태로 보냄
 2️⃣ alert Signal로 보냄
 */
import RxSwift
import Domain
import Core
import RxCocoa
import ProfileFeatureInterface
import UserNotifications

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
        
        /// 회원탈퇴 버튼 이벤트
        let withdrawalTapped: Observable<Void>
    }
    
    struct Output {
        // 알림 토글 상태 결과
        let notificationState: Driver<Bool>
                
        // 알림 권한 알림창
        let showPermissionALert: Signal<Void>
    }
    
    init(authUsecase: AuthUsecaseProtocol) {
        self.authUsecase = authUsecase
    }
    
    // 푸시 알림 권한이 허용되어 있는지 확인한다.
    private func notificationAuthorization() -> Observable<UNAuthorizationStatus> {
        Observable.create { observer in
            UNUserNotificationCenter.current()
                .getNotificationSettings { settings in
                    observer.onNext(settings.authorizationStatus)
                    observer.onCompleted()
                }
            return Disposables.create()
        }
    }
    
    func transform(input: Input) -> Output {
        
        // MARK: - Coordinator
        // 로그아웃
        input.logoutTapped// output안줄거다 owner.authUsecase.signOut()으로 로그아웃 정상처리된다 이대로유지
            .withUnretained(self)
            .flatMapLatest { owner, _ in
                owner.authUsecase.signOut()
            }
            .subscribe()
            .disposed(by: disposeBag)
        
        // 회원탈퇴
        input.withdrawalTapped
            .withUnretained(self)
            .flatMapLatest { owner, _ in
                return owner.authUsecase.deleteUserAuthAndData()
            }
            .subscribe()
            .disposed(by: disposeBag)
        
        // 1. 최초 화면 토글 상태(현재 세션 값)
        let initialState = Observable.just(userSession.session?.isPushEnabled ?? false)
        
        // 2. 사용자가 토글을 누를 때
        // - (최종 토글 상태, alert 필요 여부)
        let toggleFlow = input.notificationToggleTapped
            .withUnretained(self)
            .flatMapLatest { owner, isOn -> Observable<(Bool, Bool)> in
                
                guard let sessionUser = owner.userSession.session else {
                    return Observable.just((false, false))
                }
                
                // 1. 기존 값 저장
                let beforeIsPushEnabled = sessionUser.isPushEnabled
                
                // 🔴 OFF → 바로 서버 반영
                if !isOn {
                    // 2. 세션 먼저 변경(낙관적 업데이트)
                    owner.userSession.update(\.isPushEnabled, false)
                    
                    // 3. 서버 반영
                    var updatedUser = sessionUser
                    updatedUser.isPushEnabled = false
                    
                    return owner.authUsecase.updateUser(user: updatedUser)
                        .map { _ in (false, false) }
                        .asObservable()
                        .catch { error in
                            // 4. 실패 시 롤백
                            owner.userSession.update(\.isPushEnabled, beforeIsPushEnabled)
                            return Observable.just((beforeIsPushEnabled, false))
                        }
                }
                
                // 🟢 ON → 권한 확인
                return owner.requestIfNeeded() // 권한을 확인한다
                    .flatMapLatest { granted -> Observable<(Bool, Bool)> in
                        // 권한 거절
                        guard granted else {
                            return .just((false, true)) // false, alert 필요
                        }
                        
                        // 2. 세션 먼저 변경(낙관적 업데이트)
                        owner.userSession.update(\.isPushEnabled, true)
                        
                        // 3. 서버 반영
                        var updatedUser = sessionUser
                        updatedUser.isPushEnabled = true
                        
                        return owner.authUsecase.updateUser(user: updatedUser)
                            .map { _ in (true, false) } // 성공 시
                            .asObservable()
                            .catch { error in           // 실패시
                                // 4. 실패 시 롤백
                                owner.userSession.update(\.isPushEnabled, beforeIsPushEnabled)
                                return .just((beforeIsPushEnabled, false))
                            }
                    }
                    .share()
            }
  
        
        // merge(UI 상태)
        // - (최종 토글 상태, alert 필요 여부)에서 최종 토글 상태 꺼냄
        let notificationState = Observable
            .merge(initialState, toggleFlow.map { $0.0 })
            .asDriver(onErrorJustReturn: false)
        
        // alert
        // - (최종 토글 상태, alert 필요 여부)에서 alert 필요 여부 꺼냄
        let showPermissionALert = toggleFlow
            .filter { $0.1 }
            .mapToVoid()
            .asSignal(onErrorSignalWith: .empty())

        return Output(notificationState: notificationState,
                      showPermissionALert: showPermissionALert)
    }
    
    
    private func requestIfNeeded() -> Observable<Bool> {
        Observable.create { observer in
            UNUserNotificationCenter.current()
                .getNotificationSettings { settings in
                    switch settings.authorizationStatus {
                    // 시스템 팝업 띄움
                    case .notDetermined:
                        UNUserNotificationCenter.current()
                            .requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                                observer.onNext(granted)
                                observer.onCompleted()
                            }
                    // true
                    case .authorized:
                        observer.onNext(true)
                        observer.onCompleted()
                        
                    // false
                    case .denied:
                        observer.onNext(false)
                        observer.onCompleted()
                        
                    default:
                        observer.onNext(false)
                        observer.onCompleted()
                    }
                }
            return Disposables.create()
        }
    }
}
