import Domain
import Foundation
import RxSwift

final class DemoAdminUsecase:
    AdminUsecaseProtocol
{
    private let summaries:
        [AdminGroupSummary] = [
            AdminGroupSummary(
                groupId:
                    "family-spring",
                groupName:
                    "봄날 가족",
                memberCount: 5,
                postCount: 128,
                photoCount: 128,
                latestPostDate:
                    Date()
                        .addingTimeInterval(
                            -1_800
                        )
            ),
            AdminGroupSummary(
                groupId:
                    "friends-weekend",
                groupName:
                    "주말 친구들",
                memberCount: 8,
                postCount: 74,
                photoCount: 74,
                latestPostDate:
                    Date()
                        .addingTimeInterval(
                            -86_400
                        )
            ),
            AdminGroupSummary(
                groupId:
                    "new-family",
                groupName:
                    "새로운 가족",
                memberCount: 2,
                postCount: 0,
                photoCount: 0,
                latestPostDate: nil
            ),
        ]

    func fetchGroupSummaries()
        -> Single<
            [AdminGroupSummary]
        >
    {
        .just(summaries)
    }

    func fetchGroup(
        groupId: String
    ) -> Single<HCGroup> {
        guard
            let summary =
                summaries.first(
                    where: {
                        $0.groupId
                            == groupId
                    }
                )
        else {
            return .error(
                DomainError
                    .missingGroupId
            )
        }

        return .just(
            HCGroup(
                groupId:
                    summary.groupId,
                groupName:
                    summary.groupName,
                createdAt: .now,
                hostUserId: "demo-admin",
                inviteCode: "DEMO",
                members: [:],
                postsByDate: [:]
            )
        )
    }
}
