import Domain
import Foundation

/// 관리자 그룹 목록에서 선택할 수 있는 정렬 기준입니다.
enum AdminGroupSortOption:
    CaseIterable,
    Equatable
{
    case latestPost
    case groupCreatedAt
    case groupName
    case memberCount
    case postCount
    case photoCount

    /// 조회된 그룹을 현재 기준에 맞게 정렬합니다.
    func sort(
        _ groups:
            [AdminGroupSummary]
    ) -> [AdminGroupSummary] {
        groups.sorted {
            lhs, rhs in
            switch self {
            case .latestPost:
                return latestPostPrecedes(
                    lhs,
                    rhs
                )
            case .groupCreatedAt:
                return groupCreatedAtPrecedes(
                    lhs,
                    rhs
                )
            case .groupName:
                return namePrecedes(
                    lhs,
                    rhs
                )
            case .memberCount:
                return countPrecedes(
                    lhs.memberCount,
                    rhs.memberCount,
                    lhs: lhs,
                    rhs: rhs
                )
            case .postCount:
                return countPrecedes(
                    lhs.postCount,
                    rhs.postCount,
                    lhs: lhs,
                    rhs: rhs
                )
            case .photoCount:
                return countPrecedes(
                    lhs.photoCount,
                    rhs.photoCount,
                    lhs: lhs,
                    rhs: rhs
                )
            }
        }
    }

    /// 최근 생성된 그룹을 먼저 두고, 같은 경우 그룹명순으로 정렬합니다.
    private func groupCreatedAtPrecedes(
        _ lhs: AdminGroupSummary,
        _ rhs: AdminGroupSummary
    ) -> Bool {
        guard lhs.groupCreatedAt
            == rhs.groupCreatedAt
        else {
            return lhs.groupCreatedAt
                > rhs.groupCreatedAt
        }

        return namePrecedes(
            lhs,
            rhs
        )
    }

    /// 개수가 많은 그룹을 먼저 두고, 같은 경우 최신 게시글순으로 정렬합니다.
    private func countPrecedes(
        _ lhsCount: Int,
        _ rhsCount: Int,
        lhs: AdminGroupSummary,
        rhs: AdminGroupSummary
    ) -> Bool {
        guard lhsCount == rhsCount
        else {
            return lhsCount > rhsCount
        }

        return latestPostPrecedes(
            lhs,
            rhs
        )
    }

    /// 최신 게시글이 있는 그룹을 먼저 두고, 같은 경우 그룹명순으로 정렬합니다.
    private func latestPostPrecedes(
        _ lhs: AdminGroupSummary,
        _ rhs: AdminGroupSummary
    ) -> Bool {
        switch (
            lhs.latestPostDate,
            rhs.latestPostDate
        ) {
        case let (
            lhsDate?,
            rhsDate?
        ):
            guard lhsDate == rhsDate
            else {
                return lhsDate > rhsDate
            }
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        case (.none, .none):
            break
        }

        return namePrecedes(
            lhs,
            rhs
        )
    }

    /// 현재 언어의 문자열 비교 규칙을 따르고, 이름이 같으면 ID로 순서를 고정합니다.
    private func namePrecedes(
        _ lhs: AdminGroupSummary,
        _ rhs: AdminGroupSummary
    ) -> Bool {
        let comparison =
            lhs.groupName
                .localizedCaseInsensitiveCompare(
                    rhs.groupName
                )
        guard comparison == .orderedSame
        else {
            return comparison
                == .orderedAscending
        }

        return lhs.groupId
            < rhs.groupId
    }
}
