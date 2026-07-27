import Core
import Domain
import MemberFeatureV2Interface
import RxCocoa
import RxSwift

struct MemberScreenState:
    Equatable
{
    let members: [User]
    let birthdaySettings:
        GroupBirthdaySettings
    let canEditBirthdaySettings:
        Bool
}

final class MemberViewModel:
    MemberViewModelType
{
    var onCellImageTapped:
        ((String) -> Void)?

    private let disposeBag =
        DisposeBag()
    private let userSession:
        UserSession
    private let groupSession:
        GroupSession
    private let authUsecase:
        AuthUsecaseProtocol
    private let groupUsecase:
        GroupUsecaseProtocol

    struct Input {
        let inviteCellTapped:
            Observable<Void>
        let memberCellTapped:
            Observable<User>
        let birthdaySettingsChanged:
            Observable<
                GroupBirthdaySettings
            >
    }

    struct Output {
        let screenState:
            Driver<MemberScreenState>
        let inviteCode:
            Driver<String>
        let birthdaySettingsUpdateFailed:
            Signal<Void>
    }

    init(
        userSession: UserSession,
        groupSession: GroupSession,
        authUsecase:
            AuthUsecaseProtocol,
        groupUsecase:
            GroupUsecaseProtocol
    ) {
        self.userSession =
            userSession
        self.groupSession =
            groupSession
        self.authUsecase =
            authUsecase
        self.groupUsecase =
            groupUsecase
    }

    func transform(
        input: Input
    ) -> Output {
        let memberUIDs =
            Array(
                groupSession
                    .members.keys
            )
        let members =
            Observable
                .from(memberUIDs)
                .withUnretained(self)
                .flatMap {
                    owner, uid
                        -> Observable<User> in
                    owner.authUsecase
                        .fetchUser(uid: uid)
                        .asObservable()
                        .catchAndReturn(nil)
                        .compactMap { $0 }
                }
                .toArray()
                .asObservable()
                .share(replay: 1)

        let sortedMembers =
            members
                .withUnretained(self)
                .map {
                    owner, users
                        -> [User] in
                    let myUID =
                        owner.userSession
                            .userId
                    let me = users.first {
                        $0.uid == myUID
                    }
                    let others =
                        users
                            .filter {
                                $0.uid
                                    != myUID
                            }
                            .sorted {
                                $0.registerDate
                                    < $1.registerDate
                            }
                    return (
                        [me]
                            .compactMap {
                                $0
                            }
                            + others
                    )
                }
                .share(replay: 1)

        let groupState =
            observeGroupSession()
                .share(replay: 1)

        let screenState =
            Observable
                .combineLatest(
                    sortedMembers,
                    groupState
                ) {
                    [weak self]
                    members,
                    group
                        -> MemberScreenState in
                    MemberScreenState(
                        members: members,
                        birthdaySettings:
                            group?
                                .resolvedBirthdaySettings
                                ?? .defaultValue,
                        canEditBirthdaySettings:
                            self?
                                .userSession
                                .userId
                                .map {
                                    userId in
                                    group?
                                        .members[
                                            userId
                                        ] != nil
                                }
                                ?? false
                    )
                }
                .asDriver(
                    onErrorJustReturn:
                        MemberScreenState(
                            members: [],
                            birthdaySettings:
                                .defaultValue,
                            canEditBirthdaySettings:
                                false
                        )
                )

        let inviteCode =
            input.inviteCellTapped
                .compactMap {
                    [weak self] in
                    self?.groupSession
                        .inviteCode
                }
                .filter {
                    !$0.isEmpty
                }
                .asDriver(
                    onErrorJustReturn: ""
                )

        input.memberCellTapped
            .compactMap(
                \.profileImageURL
            )
            .bind(with: self) {
                owner, imageURL in
                owner
                    .onCellImageTapped?(
                        imageURL
                    )
            }
            .disposed(by: disposeBag)

        let birthdaySettingsUpdate =
            input
                .birthdaySettingsChanged
                .withUnretained(self)
                .flatMapLatest {
                    owner, settings in
                    owner.groupUsecase
                        .updateBirthdaySettings(
                            settings
                        )
                        .asObservable()
                        .materialize()
                }
                .share()

        let birthdaySettingsUpdateFailed =
            birthdaySettingsUpdate
                .compactMap {
                    event -> Void? in
                    guard
                        event.error
                            != nil
                    else {
                        return nil
                    }
                    return ()
                }
                .asSignal(
                    onErrorJustReturn: ()
                )

        return Output(
            screenState:
                screenState,
            inviteCode:
                inviteCode,
            birthdaySettingsUpdateFailed:
                birthdaySettingsUpdateFailed
        )
    }

    private func observeGroupSession()
        -> Observable<SessionGroup?>
    {
        Observable.create {
            [weak groupSession] observer in
            guard let groupSession else {
                observer.onNext(nil)
                observer.onCompleted()
                return Disposables
                    .create()
            }
            let observerID =
                groupSession.bind {
                    group in
                    observer.onNext(group)
                }
            return Disposables
                .create {
                    groupSession
                        .removeObserver(
                            observerID
                        )
                }
        }
    }
}
