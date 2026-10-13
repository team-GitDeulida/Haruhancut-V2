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
                owner.isSavingRelay
                    .accept(true)
                // 세션의 생일을 먼저 바꾸고 서버에 저장한다. 실패하면 Usecase가 되돌린다
                return owner
                    .authUsecase
                    .updateBirthday(
                        Self.normalizedBirthday(
                            birthdayDate
                        )
                    )
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
