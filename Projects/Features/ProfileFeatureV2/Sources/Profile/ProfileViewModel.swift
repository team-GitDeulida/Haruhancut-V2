import Core
import Domain
import ProfileFeatureV2Interface
import RxCocoa
import RxSwift
import UIKit

final class ProfileViewModel:
    ProfileViewModelType
{
    var onProfileImageTapped:
        ((String) -> Void)?
    var onProfileImageEditButtonTapped:
        ((@escaping (UIImage) -> Void) -> Void)?
    var onNicknameEditButtonTapped:
        (() -> Void)?
    var onSettingButtonTapped:
        (() -> Void)?
    var onImageTapped:
        ((Post) -> Void)?

    struct Input {
        let profileImageTapped:
            Observable<Void>
        let profileImageEditTapped:
            Observable<Void>
        let nicknameEditTapped:
            Observable<Void>
        let settingTapped:
            Observable<Void>
        let imageTapped:
            Observable<Post>
        let reload:
            Observable<Void>
        let viewWillAppear:
            Observable<Void>
    }

    struct Output {
        let user: Driver<User>
        let myPosts: Driver<[Post]>
        let isLoading: Driver<Bool>
    }

    private let disposeBag =
        DisposeBag()
    private let reloadUserRelay =
        PublishRelay<Void>()
    private let isLoadingRelay =
        BehaviorRelay<Bool>(
            value: false
        )

    private let userSession:
        UserSession
    private let authUsecase:
        AuthUsecaseProtocol
    private let groupUsecase:
        GroupUsecaseProtocol

    init(
        userSession: UserSession,
        authUsecase: AuthUsecaseProtocol,
        groupUsecase:
            GroupUsecaseProtocol
    ) {
        self.userSession = userSession
        self.authUsecase = authUsecase
        self.groupUsecase = groupUsecase
    }

    func transform(
        input: Input
    ) -> Output {
        let user = Observable.merge(
            input.viewWillAppear,
            reloadUserRelay.asObservable()
        )
        .withUnretained(self)
        .flatMapLatest { owner, _ in
            owner.authUsecase
                .loadAndFetchUser()
                .catch { _ in .empty() }
        }
        .share(replay: 1)

        let initialGroup =
            groupUsecase
                .loadAndFetchGroup()

        let reloadedGroup =
            input.reload
                .withUnretained(self)
                .flatMapLatest {
                    owner, _ in
                    owner.groupUsecase
                        .loadAndFetchGroup()
                        .catch {
                            _ in .empty()
                        }
                }

        let group = Observable.merge(
            initialGroup,
            reloadedGroup
        )
        .share(replay: 1)

        let userID =
            userSession.userId
        let posts = group
            .map { group in
                group.postsByDate
                    .values
                    .flatMap { $0 }
                    .filter {
                        $0.userId == userID
                    }
                    .sorted {
                        $0.createdAt >
                            $1.createdAt
                    }
            }
            .distinctUntilChanged()
            .asDriver(
                onErrorJustReturn: []
            )

        input.profileImageTapped
            .withLatestFrom(user)
            .compactMap(\.profileImageURL)
            .bind(with: self) {
                owner, imageURL in
                owner
                    .onProfileImageTapped?(
                        imageURL
                    )
            }
            .disposed(by: disposeBag)

        input.profileImageEditTapped
            .bind(with: self) {
                owner, _ in
                owner
                    .onProfileImageEditButtonTapped?
                { image in
                    owner.isLoadingRelay
                        .accept(true)
                    owner.authUsecase
                        .updateProfileImageAndReloadSession(
                            image: image
                        )
                        .subscribe(
                            onSuccess: {
                                _ in
                                owner.reloadUserRelay
                                    .accept(())
                                owner.isLoadingRelay
                                    .accept(false)
                            },
                            onFailure: {
                                _ in
                                owner.isLoadingRelay
                                    .accept(false)
                            }
                        )
                        .disposed(
                            by:
                                owner
                                    .disposeBag
                        )
                }
            }
            .disposed(by: disposeBag)

        input.nicknameEditTapped
            .bind(with: self) {
                owner, _ in
                owner
                    .onNicknameEditButtonTapped?()
            }
            .disposed(by: disposeBag)

        input.settingTapped
            .bind(with: self) {
                owner, _ in
                owner
                    .onSettingButtonTapped?()
            }
            .disposed(by: disposeBag)

        input.imageTapped
            .bind(with: self) {
                owner, post in
                owner.onImageTapped?(post)
            }
            .disposed(by: disposeBag)

        return Output(
            user: user.asDriver(
                onErrorDriveWith: .empty()
            ),
            myPosts: posts,
            isLoading:
                isLoadingRelay.asDriver()
        )
    }
}
