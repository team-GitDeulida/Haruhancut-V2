import AdminFeatureInterface
import Core
import Domain
import RxCocoa
import RxSwift

struct AdminScreenState:
    Equatable
{
    let groups:
        [AdminGroupSummary]
    let isLoading: Bool
}

final class AdminViewModel:
    AdminViewModelType
{
    var onGroupTapped:
        ((AdminGroupSummary) -> Void)?

    private let adminUsecase:
        AdminUsecaseProtocol
    private let disposeBag =
        DisposeBag()

    struct Input {
        let reload:
            Observable<Void>
        let groupTapped:
            Observable<AdminGroupSummary>
    }

    struct Output {
        let screenState:
            Driver<AdminScreenState>
        let loadFailed:
            Signal<Void>
    }

    init(
        adminUsecase:
            AdminUsecaseProtocol
    ) {
        self.adminUsecase =
            adminUsecase
    }

    func transform(
        input: Input
    ) -> Output {
        input.groupTapped
            .bind(with: self) {
                owner, group in
                owner.onGroupTapped?(
                    group
                )
            }
            .disposed(by: disposeBag)

        let loadEvent =
            input.reload
                .startWith(())
                .withUnretained(self)
                .flatMapLatest {
                    owner, _ in
                    owner.adminUsecase
                        .fetchGroupSummaries()
                        .asObservable()
                        .materialize()
                }
                .share()

        let groups =
            loadEvent
                .compactMap(\.element)
                .startWith([])

        let isLoading =
            Observable.merge(
                input.reload
                    .startWith(())
                    .map { true },
                loadEvent
                    .map { _ in false }
            )
            .distinctUntilChanged()

        let screenState =
            Observable
                .combineLatest(
                    groups,
                    isLoading
                ) {
                    AdminScreenState(
                        groups: $0,
                        isLoading: $1
                    )
                }
                .asDriver(
                    onErrorJustReturn:
                        AdminScreenState(
                            groups: [],
                            isLoading: false
                        )
                )

        let loadFailed =
            loadEvent
                .compactMap {
                    $0.error == nil
                        ? nil
                        : ()
                }
                .asSignal(
                    onErrorJustReturn: ()
                )

        return Output(
            screenState:
                screenState,
            loadFailed:
                loadFailed
        )
    }
}
