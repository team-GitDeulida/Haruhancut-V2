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
    var onBirthdayEditButtonTapped:
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
        let birthdayEditTapped:
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
        // 저장된 유저를 그린다. 닉네임·프로필 사진·생일을 바꾸면 세션이 바뀌어 바로 다시 그린다
        let user = authUsecase
            .observeUser()
            .catch { _ in .empty() }
            .share(replay: 1)

        // 화면에 들어올 때마다 서버 유저로 갱신한다. 받은 유저는 세션에 저장돼 위 구독으로 온다
        input.viewWillAppear
            .withUnretained(self)
            .flatMapLatest { owner, _ in
                owner.authUsecase
                    .loadAndFetchUser()
                    .ignoreElements()
                    .catch { _ in .empty() }
            }
            .subscribe()
            .disposed(by: disposeBag)

        // 저장된 그룹에서 내 게시물을 그린다. 다른 화면에서 올리거나 지워도 바로 바뀐다
        let group = groupUsecase
            .observeGroup()
            .catch { _ in .empty() }
            .share(replay: 1)

        // 처음에는 최근에 받은 그룹이 없을 때만, 새로고침하면 항상 서버 그룹을 받아 저장한다
        Observable.merge(
            .just(false),
            input.reload.map { true }
        )
        .withUnretained(self)
        .flatMapLatest { owner, force in
            (force
                ? owner.groupUsecase.refreshGroupResult()
                : owner.groupUsecase.fetchGroupResult())
                .ignoreElements()
                .catch { _ in .empty() }
        }
        .subscribe()
        .disposed(by: disposeBag)

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
                                // 세션이 바뀌어 유저 구독으로 새 사진이 온다
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

        input.birthdayEditTapped
            .bind(with: self) {
                owner, _ in
                owner
                    .onBirthdayEditButtonTapped?()
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
