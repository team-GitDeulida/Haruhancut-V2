import Core
import Domain
import Foundation
import ProfileFeatureV2Interface
import RxCocoa
import RxRelay
import RxSwift

final class BirthdayEditViewModel:
    BirthdayEditViewModelType
{
    var onPopButtonTapped:
        (() -> Void)?

    struct Input {
        let birthdayDate:
            Observable<Date>
        let endButtonTapped:
            Observable<Void>
    }

    struct Output {
        let initialBirthdayDate:
            Driver<Date>
        let isSaving:
            Driver<Bool>
        let saveFailed:
            Signal<Void>
    }

    private let disposeBag =
        DisposeBag()
    private let userSession:
        UserSession
    private let authUsecase:
        AuthUsecaseProtocol
    private let isSavingRelay =
        BehaviorRelay<Bool>(
            value: false
        )
    private let saveFailedRelay =
        PublishRelay<Void>()

    init(
        userSession: UserSession,
        authUsecase:
            AuthUsecaseProtocol
    ) {
        self.userSession =
            userSession
        self.authUsecase =
            authUsecase
    }

    func transform(
        input: Input
    ) -> Output {
        input.endButtonTapped
            .withLatestFrom(
                input.birthdayDate
            )
            .withUnretained(self)
            .filter {
                owner, _ in
                !owner
                    .isSavingRelay
                    .value
            }
            .flatMapLatest {
                owner, birthdayDate
                    -> Observable<
                        Event<User>
                    > in
                guard
                    var user =
                        owner
                            .userSession
                            .session
                else {
                    return Observable
                        .error(
                            DomainError
                                .missingDomainSession
                        )
                        .materialize()
                }

                owner.isSavingRelay
                    .accept(true)
                user.birthdayDate =
                    Self.normalizedBirthday(
                        birthdayDate
                    )

                return owner
                    .authUsecase
                    .updateUser(user: user)
                    .do(onSuccess: {
                        [weak owner] user in
                        owner?
                            .userSession
                            .update(user)
                    })
                    .asObservable()
                    .materialize()
            }
            .observe(
                on:
                    MainScheduler
                        .instance
            )
            .subscribe(with: self) {
                owner, event in
                switch event {
                case .next:
                    owner.isSavingRelay
                        .accept(false)
                    owner
                        .onPopButtonTapped?()
                case .error:
                    owner.isSavingRelay
                        .accept(false)
                    owner.saveFailedRelay
                        .accept(())
                case .completed:
                    break
                }
            }
            .disposed(by: disposeBag)

        let initialBirthdayDate =
            Observable.just(
                userSession
                    .session?
                    .birthdayDate
                    ?? .now
            )
            .asDriver(
                onErrorJustReturn:
                    .now
            )

        return Output(
            initialBirthdayDate:
                initialBirthdayDate,
            isSaving:
                isSavingRelay
                    .asDriver(),
            saveFailed:
                saveFailedRelay
                    .asSignal()
        )
    }

    static func normalizedBirthday(
        _ date: Date,
        calendar:
            Calendar = .autoupdatingCurrent
    ) -> Date {
        calendar.startOfDay(
            for: min(date, .now)
        )
    }
}
