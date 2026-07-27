import Core
import RxSwift

/// 관리자 화면에서 사용하는 그룹 조회 기능입니다.
public protocol AdminUsecaseProtocol {
    func fetchGroupSummaries()
        -> Single<[AdminGroupSummary]>

    func fetchGroup(
        groupId: String
    ) -> Single<HCGroup>
}

/// 현재 사용자 권한을 확인한 뒤 관리자 저장소에 접근합니다.
public final class AdminUsecaseImpl:
    AdminUsecaseProtocol
{
    private let repository:
        AdminRepositoryProtocol
    private let userSession:
        UserSession

    public init(
        repository:
            AdminRepositoryProtocol,
        userSession:
            UserSession
    ) {
        self.repository = repository
        self.userSession = userSession
    }

    public func fetchGroupSummaries()
        -> Single<[AdminGroupSummary]>
    {
        guard userSession.isAdmin
        else {
            return .error(
                DomainError
                    .adminPermissionRequired
            )
        }

        return repository
            .fetchGroupSummaries()
            .map {
                summaries in
                summaries.sorted {
                    lhs, rhs in
                    switch (
                        lhs.latestPostDate,
                        rhs.latestPostDate
                    ) {
                    case let (
                        lhsDate?,
                        rhsDate?
                    ):
                        if lhsDate == rhsDate {
                            return lhs.groupName
                                < rhs.groupName
                        }
                        return lhsDate > rhsDate
                    case (.some, .none):
                        return true
                    case (.none, .some):
                        return false
                    case (.none, .none):
                        return lhs.groupName
                            < rhs.groupName
                    }
                }
            }
    }

    public func fetchGroup(
        groupId: String
    ) -> Single<HCGroup> {
        guard userSession.isAdmin
        else {
            return .error(
                DomainError
                    .adminPermissionRequired
            )
        }

        return repository.fetchGroup(
            groupId: groupId
        )
    }
}
