import Domain
import RxSwift

/// Firebase 그룹 데이터를 관리자 화면용 모델로 변환합니다.
public final class AdminRepositoryImpl:
    AdminRepositoryProtocol
{
    private let firebaseAuthManager:
        FirebaseAuthManagerProtocol

    public init(
        firebaseAuthManager:
            FirebaseAuthManagerProtocol
    ) {
        self.firebaseAuthManager =
            firebaseAuthManager
    }

    public func fetchGroupSummaries()
        -> Single<[AdminGroupSummary]>
    {
        firebaseAuthManager
            .fetchGroups()
            .map {
                groups in
                groups.map {
                    AdminGroupSummary(
                        group: $0
                    )
                }
            }
    }

    public func fetchGroup(
        groupId: String
    ) -> Single<HCGroup> {
        firebaseAuthManager.fetchGroup(
            groupId: groupId
        )
    }
}
