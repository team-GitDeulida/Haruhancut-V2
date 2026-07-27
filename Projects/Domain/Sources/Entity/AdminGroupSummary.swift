import Foundation

/// 관리자 목록에서 사용하는 그룹 운영 현황입니다.
public struct AdminGroupSummary:
    Equatable,
    Identifiable
{
    public var id: String {
        groupId
    }

    public let groupId: String
    public let groupName: String
    public let memberCount: Int
    public let postCount: Int
    public let photoCount: Int
    public let groupCreatedAt: Date
    public let latestPostDate: Date?

    public init(
        groupId: String,
        groupName: String,
        memberCount: Int,
        postCount: Int,
        photoCount: Int,
        groupCreatedAt: Date = .distantPast,
        latestPostDate: Date?
    ) {
        self.groupId = groupId
        self.groupName = groupName
        self.memberCount = memberCount
        self.postCount = postCount
        self.photoCount = photoCount
        self.groupCreatedAt = groupCreatedAt
        self.latestPostDate = latestPostDate
    }

    /// 그룹의 게시글과 멤버 데이터를 관리자 목록용 통계로 축약합니다.
    public init(group: HCGroup) {
        let posts =
            group.postsByDate
                .values
                .flatMap { $0 }

        self.init(
            groupId: group.groupId,
            groupName: group.groupName,
            memberCount: group.members.count,
            postCount: posts.count,
            photoCount: posts.filter {
                !$0.imageURL.isEmpty
            }.count,
            groupCreatedAt: group.createdAt,
            latestPostDate:
                posts.map(\.createdAt).max()
        )
    }
}
