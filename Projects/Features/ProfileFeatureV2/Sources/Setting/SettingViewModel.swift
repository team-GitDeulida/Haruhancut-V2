import Core
import Domain
import ProfileFeatureV2Interface
import RxCocoa
import RxSwift
import UserNotifications

final class SettingViewModel:
    SettingViewModelType
{
    var onLogoutTapped:
        (() -> Void)?

    struct Input {
        let logoutTapped:
            Observable<Void>
        let notificationToggleTapped:
            Observable<Bool>
        let withdrawalTapped:
            Observable<Void>
    }

    struct Output {
        let notificationState:
            Driver<Bool>
        let showPermissionAlert:
            Signal<Void>
    }

    private let disposeBag =
        DisposeBag()
    private let authUsecase:
        AuthUsecaseProtocol

    @Dependency
    private var userSession:
        UserSession

    init(
        authUsecase:
            AuthUsecaseProtocol
    ) {
        self.authUsecase = authUsecase
    }

    func transform(
        input: Input
    ) -> Output {
        input.logoutTapped
            .withUnretained(self)
            .flatMapLatest {
                owner, _ in
                owner.authUsecase
                    .signOut()
            }
            .observe(on: MainScheduler.instance)
            .subscribe(
                with: self,
                onNext: {
                    owner, _ in
                    owner.onLogoutTapped?()
                }
            )
            .disposed(by: disposeBag)

        input.withdrawalTapped
            .withUnretained(self)
            .flatMapLatest {
                owner, _ in
                owner.authUsecase
                    .deleteUserAuthAndData()
            }
            .subscribe()
            .disposed(by: disposeBag)

        let initialState =
            Observable.just(
                userSession.session?
                    .isPushEnabled
                ?? false
            )

        let toggleFlow =
            input.notificationToggleTapped
                .withUnretained(self)
                .flatMapLatest {
                    owner, isOn
                        -> Observable<
                            (
                                state: Bool,
                                needsAlert: Bool
                            )
                        >
                    in
                    owner.updateNotification(
                        isOn: isOn
                    )
                }
                .share(
                    replay: 1,
                    scope: .whileConnected
                )

        let notificationState =
            Observable.merge(
                initialState,
                toggleFlow.map {
                    $0.state
                }
            )
            .asDriver(
                onErrorJustReturn: false
            )

        let showPermissionAlert =
            toggleFlow
                .filter {
                    $0.needsAlert
                }
                .map { _ in }
                .asSignal(
                    onErrorSignalWith:
                        .empty()
                )

        return Output(
            notificationState:
                notificationState,
            showPermissionAlert:
                showPermissionAlert
        )
    }

    private func updateNotification(
        isOn: Bool
    ) -> Observable<
        (
            state: Bool,
            needsAlert: Bool
        )
    > {
        guard
            let sessionUser =
                userSession.session
        else {
            return .just(
                (false, false)
            )
        }

        let previousState =
            sessionUser.isPushEnabled

        guard isOn else {
            userSession.update(
                \.isPushEnabled,
                false
            )
            var updatedUser =
                sessionUser
            updatedUser.isPushEnabled =
                false

            return authUsecase
                .updateUser(
                    user: updatedUser
                )
                .map { _ in
                    (false, false)
                }
                .asObservable()
                .catch {
                    [weak self] _ in
                    self?.userSession.update(
                        \.isPushEnabled,
                        previousState
                    )
                    return .just(
                        (
                            previousState,
                            false
                        )
                    )
                }
        }

        return requestAuthorizationIfNeeded()
            .flatMapLatest {
                [weak self] granted
                    -> Observable<
                        (
                            state: Bool,
                            needsAlert: Bool
                        )
                    >
                in
                guard
                    let self,
                    granted
                else {
                    return .just(
                        (false, true)
                    )
                }

                userSession.update(
                    \.isPushEnabled,
                    true
                )
                var updatedUser =
                    sessionUser
                updatedUser.isPushEnabled =
                    true

                return authUsecase
                    .updateUser(
                        user: updatedUser
                    )
                    .map { _ in
                        (true, false)
                    }
                    .asObservable()
                    .catch {
                        [weak self] _ in
                        self?.userSession
                            .update(
                                \.isPushEnabled,
                                previousState
                            )
                        return .just(
                            (
                                previousState,
                                false
                            )
                        )
                    }
            }
    }

    private func requestAuthorizationIfNeeded()
        -> Observable<Bool>
    {
        Observable.create { observer in
            UNUserNotificationCenter
                .current()
                .getNotificationSettings {
                    settings in
                    switch settings
                        .authorizationStatus
                    {
                    case .notDetermined:
                        UNUserNotificationCenter
                            .current()
                            .requestAuthorization(
                                options: [
                                    .alert,
                                    .badge,
                                    .sound,
                                ]
                            ) {
                                granted, _ in
                                observer.onNext(
                                    granted
                                )
                                observer
                                    .onCompleted()
                            }
                    case .authorized,
                         .provisional,
                         .ephemeral:
                        observer.onNext(true)
                        observer.onCompleted()
                    case .denied:
                        observer.onNext(false)
                        observer.onCompleted()
                    @unknown default:
                        observer.onNext(false)
                        observer.onCompleted()
                    }
                }
            return Disposables.create()
        }
    }
}
