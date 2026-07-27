import Domain
import ProfileFeatureV2Interface
import RxCocoa
import RxSwift

final class NicknameEditViewModel:
    NicknameEditViewModelType
{
    var onPopButtonTapped:
        (() -> Void)?

    struct Input {
        let nicknameText:
            Observable<String>
        let endButtonTapped:
            Observable<Void>
    }

    struct Output {
        let isNicknameValid:
            Driver<Bool>
    }

    private let disposeBag =
        DisposeBag()
    private let authUsecase:
        AuthUsecaseProtocol

    init(
        authUsecase:
            AuthUsecaseProtocol
    ) {
        self.authUsecase = authUsecase
    }

    func transform(
        input: Input
    ) -> Output {
        let nickname =
            input.nicknameText
                .map {
                    $0.trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )
                }
                .share(replay: 1)

        let isNicknameValid =
            nickname
                .map { !$0.isEmpty }
                .distinctUntilChanged()
                .asDriver(
                    onErrorJustReturn: false
                )

        input.endButtonTapped
            .withLatestFrom(nickname)
            .withUnretained(self)
            .flatMapLatest {
                owner, nickname
                    -> Observable<User> in
                owner.authUsecase
                    .updateNicknameAndReloadSession(
                        nickname: nickname
                    )
                    .asObservable()
                    .catch { _ in .empty() }
            }
            .observe(on: MainScheduler.instance)
            .bind(with: self) {
                owner, _ in
                owner.onPopButtonTapped?()
            }
            .disposed(by: disposeBag)

        return Output(
            isNicknameValid:
                isNicknameValid
        )
    }
}
