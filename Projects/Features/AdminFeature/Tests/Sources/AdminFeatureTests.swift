@testable import AdminFeature
import Core
import Domain
import Foundation
import RxSwift
import XCTest

final class AdminFeatureTests:
    XCTestCase
{
    func testGroupSortOptionsOrderGroupsBySelectedMetric() {
        let alpha =
            AdminGroupSummary(
                groupId: "alpha",
                groupName: "Alpha",
                memberCount: 3,
                postCount: 1,
                photoCount: 1,
                groupCreatedAt:
                    Date(
                        timeIntervalSince1970:
                            200
                    ),
                latestPostDate:
                    Date(
                        timeIntervalSince1970:
                            100
                    )
            )
        let beta =
            AdminGroupSummary(
                groupId: "beta",
                groupName: "Beta",
                memberCount: 1,
                postCount: 4,
                photoCount: 3,
                groupCreatedAt:
                    Date(
                        timeIntervalSince1970:
                            300
                    ),
                latestPostDate:
                    Date(
                        timeIntervalSince1970:
                            200
                    )
            )
        let charlie =
            AdminGroupSummary(
                groupId: "charlie",
                groupName: "Charlie",
                memberCount: 2,
                postCount: 2,
                photoCount: 5,
                groupCreatedAt:
                    Date(
                        timeIntervalSince1970:
                            100
                    ),
                latestPostDate: nil
            )
        let groups = [
            charlie,
            alpha,
            beta,
        ]

        XCTAssertEqual(
            AdminGroupSortOption
                .latestPost
                .sort(groups)
                .map(\.groupId),
            [
                "beta",
                "alpha",
                "charlie",
            ]
        )
        XCTAssertEqual(
            AdminGroupSortOption
                .groupCreatedAt
                .sort(groups)
                .map(\.groupId),
            [
                "beta",
                "alpha",
                "charlie",
            ]
        )
        XCTAssertEqual(
            AdminGroupSortOption
                .groupName
                .sort(groups)
                .map(\.groupId),
            [
                "alpha",
                "beta",
                "charlie",
            ]
        )
        XCTAssertEqual(
            AdminGroupSortOption
                .memberCount
                .sort(groups)
                .map(\.groupId),
            [
                "alpha",
                "charlie",
                "beta",
            ]
        )
        XCTAssertEqual(
            AdminGroupSortOption
                .postCount
                .sort(groups)
                .map(\.groupId),
            [
                "beta",
                "charlie",
                "alpha",
            ]
        )
        XCTAssertEqual(
            AdminGroupSortOption
                .photoCount
                .sort(groups)
                .map(\.groupId),
            [
                "charlie",
                "beta",
                "alpha",
            ]
        )
    }

    func testGroupSummaryCountsPostsAndPhotos() {
        let olderPost =
            makePost(
                id: "older",
                imageURL:
                    "https://example.com/older.jpg",
                createdAt:
                    Date(
                        timeIntervalSince1970:
                            100
                    )
            )
        let latestPost =
            makePost(
                id: "latest",
                imageURL: "",
                createdAt:
                    Date(
                        timeIntervalSince1970:
                            200
                    )
            )
        let group =
            HCGroup(
                groupId: "group",
                groupName: "가족",
                createdAt: .now,
                hostUserId: "owner",
                inviteCode: "CODE",
                members: [
                    "owner": "joined",
                    "member": "joined",
                ],
                postsByDate: [
                    "2026-01-01": [
                        olderPost,
                        latestPost,
                    ],
                ]
            )

        let summary =
            AdminGroupSummary(
                group: group
            )

        XCTAssertEqual(
            summary.memberCount,
            2
        )
        XCTAssertEqual(
            summary.postCount,
            2
        )
        XCTAssertEqual(
            summary.photoCount,
            1
        )
        XCTAssertEqual(
            summary.groupCreatedAt,
            group.createdAt
        )
        XCTAssertEqual(
            summary.latestPostDate,
            latestPost.createdAt
        )
    }

    func testAdminUsecaseRejectsNonAdminUser() {
        let userSession =
            UserSession(
                storage:
                    TestMemoryStorage(),
                storageKey:
                    "admin-test-user"
            )
        userSession.update(
            makeUser(
                isAdmin: nil
            )
        )
        let usecase =
            AdminUsecaseImpl(
                repository:
                    TestAdminRepository(),
                userSession:
                    userSession
            )
        let expectation =
            expectation(
                description:
                    "권한 오류"
            )

        _ = usecase
            .fetchGroupSummaries()
            .subscribe(
                onSuccess: {
                    _ in
                    XCTFail(
                        "일반 사용자는 관리자 목록을 조회할 수 없어야 합니다."
                    )
                },
                onFailure: {
                    error in
                    guard
                        case DomainError
                            .adminPermissionRequired =
                            error
                    else {
                        XCTFail(
                            "예상하지 못한 오류: \(error)"
                        )
                        return
                    }
                    expectation
                        .fulfill()
                }
            )

        wait(
            for: [expectation],
            timeout: 1
        )
    }

    func testAdminUsecaseSortsLatestGroupFirst() {
        let userSession =
            UserSession(
                storage:
                    TestMemoryStorage(),
                storageKey:
                    "admin-test-user"
            )
        userSession.update(
            makeUser(
                isAdmin: true
            )
        )
        let older =
            AdminGroupSummary(
                groupId: "older",
                groupName: "이전",
                memberCount: 1,
                postCount: 1,
                photoCount: 1,
                latestPostDate:
                    Date(
                        timeIntervalSince1970:
                            100
                    )
            )
        let latest =
            AdminGroupSummary(
                groupId: "latest",
                groupName: "최근",
                memberCount: 1,
                postCount: 1,
                photoCount: 1,
                latestPostDate:
                    Date(
                        timeIntervalSince1970:
                            200
                    )
            )
        let repository =
            TestAdminRepository(
                summaries: [
                    older,
                    latest,
                ]
            )
        let usecase =
            AdminUsecaseImpl(
                repository:
                    repository,
                userSession:
                    userSession
            )
        let expectation =
            expectation(
                description:
                    "정렬 결과"
            )

        _ = usecase
            .fetchGroupSummaries()
            .subscribe(
                onSuccess: {
                    summaries in
                    XCTAssertEqual(
                        summaries.map(\.groupId),
                        [
                            "latest",
                            "older",
                        ]
                    )
                    expectation
                        .fulfill()
                }
            )

        wait(
            for: [expectation],
            timeout: 1
        )
    }

    func testFetchingGroupForAdminPreviewDoesNotChangeCurrentGroupSession() {
        let userSession =
            UserSession(
                storage:
                    TestMemoryStorage(),
                storageKey:
                    "admin-preview-user"
            )
        userSession.update(
            makeUser(
                isAdmin: true
            )
        )
        let groupSession =
            GroupSession(
                storage:
                    TestMemoryStorage(),
                storageKey:
                    "admin-preview-group"
            )
        let currentGroup =
            makeGroup(
                id: "current",
                name: "현재 가족"
            )
        let previewGroup =
            makeGroup(
                id: "preview",
                name: "관리 대상 가족"
            )
        groupSession.update(
            currentGroup.toSession()
        )
        let usecase =
            AdminUsecaseImpl(
                repository:
                    TestAdminRepository(
                        group: previewGroup
                    ),
                userSession:
                    userSession
            )
        let expectation =
            expectation(
                description:
                    "관리자 그룹 미리보기"
            )

        _ = usecase
            .fetchGroup(
                groupId:
                    previewGroup.groupId
            )
            .subscribe(
                onSuccess: {
                    group in
                    XCTAssertEqual(
                        group.groupId,
                        previewGroup.groupId
                    )
                    XCTAssertEqual(
                        groupSession.groupId,
                        currentGroup.groupId
                    )
                    expectation
                        .fulfill()
                }
            )

        wait(
            for: [expectation],
            timeout: 1
        )
    }

    private func makeGroup(
        id: String,
        name: String
    ) -> HCGroup {
        HCGroup(
            groupId: id,
            groupName: name,
            createdAt: .now,
            hostUserId: "owner",
            inviteCode: "CODE",
            members: [
                "owner": "joined",
            ],
            postsByDate: [:]
        )
    }

    private func makePost(
        id: String,
        imageURL: String,
        createdAt: Date
    ) -> Post {
        Post(
            postId: id,
            userId: "user",
            nickname: "사용자",
            profileImageURL: nil,
            imageURL: imageURL,
            createdAt: createdAt,
            likeCount: 0,
            comments: [:]
        )
    }

    private func makeUser(
        isAdmin: Bool?
    ) -> User {
        User(
            uid: "user",
            registerDate: .now,
            loginPlatform: .apple,
            nickname: "사용자",
            birthdayDate: .now,
            gender: .other,
            isPushEnabled: true,
            groupId: "group",
            isAdmin: isAdmin
        )
    }
}

private final class TestMemoryStorage:
    UserDefaultsStorageProtocol
{
    private var values:
        [String: Any] = [:]

    func set<T>(
        _ value: T?,
        forKey key: String
    ) {
        values[key] = value
    }

    func get<T>(
        forKey key: String
    ) -> T? {
        values[key] as? T
    }

    func remove(
        _ key: String
    ) {
        values.removeValue(
            forKey: key
        )
    }
}

private final class TestAdminRepository:
    AdminRepositoryProtocol
{
    private let summaries:
        [AdminGroupSummary]
    private let group:
        HCGroup?

    init(
        summaries:
            [AdminGroupSummary] = [],
        group: HCGroup? = nil
    ) {
        self.summaries =
            summaries
        self.group = group
    }

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
        guard let group,
              group.groupId == groupId
        else {
            return .error(
                DomainError
                    .missingGroupId
            )
        }

        return .just(group)
    }
}
