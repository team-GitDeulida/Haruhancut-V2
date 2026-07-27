import Core
import Domain
import MemberFeatureV2Interface
import RxCocoa
import RxSwift

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

    struct Input {
        let inviteCellTapped:
            Observable<Void>
        let memberCellTapped:
            Observable<User>
    }

    struct Output {
        let sortedMembers:
            Driver<[User]>
        let inviteCode:
            Driver<String>
    }

    init(
        userSession: UserSession,
        groupSession: GroupSession,
        authUsecase:
            AuthUsecaseProtocol
    ) {
        self.userSession =
            userSession
        self.groupSession =
            groupSession
        self.authUsecase =
            authUsecase
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
                .asDriver(
                    onErrorJustReturn: []
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

        return Output(
            sortedMembers:
                sortedMembers,
            inviteCode:
                inviteCode
        )
    }
}
