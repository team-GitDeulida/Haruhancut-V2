//
//  GroupUsecaseFetchTests.swift
//  DomainTests
//
//  Created by 김동현 on 10/12/26.
//

import Core
import RxSwift
import UIKit
import XCTest
@testable import Domain

/// 그룹 조회가 서버 응답(값·없음·실패)에 따라 세션을 다루는지 확인합니다.
final class GroupUsecaseFetchTests: XCTestCase {
    private enum TestError: Error {
        case remote
    }

    private var repository: FakeGroupRepository!
    private var userSession: UserSession!
    private var groupSession: GroupSession!
    private var sut: GroupUsecaseImpl!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        repository = FakeGroupRepository()
        userSession = UserSession(
            storage: MemoryStorage(),
            storageKey: "GroupUsecaseFetchTests.user"
        )
        groupSession = GroupSession(
            storage: MemoryStorage(),
            storageKey: "GroupUsecaseFetchTests.group"
        )
        userSession.update(makeUser(groupId: "group"))
        groupSession.update(makeGroup(name: "cached").toSession())
        sut = GroupUsecaseImpl(
            groupRepository: repository,
            userSession: userSession,
            groupSession: groupSession
        )
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        disposeBag = nil
        sut = nil
        groupSession = nil
        userSession = nil
        repository = nil
        super.tearDown()
    }

    // MARK: - loadAndFetchGroup

    func testLoadAndFetchGroupSendsCachedGroupThenSavesServerGroup() {
        repository.fetchGroupResponse = .just(makeGroup(name: "server"))

        let recorder = record(sut.loadAndFetchGroup())

        XCTAssertEqual(recorder.values.map(\.groupName), ["cached", "server"])
        XCTAssertTrue(recorder.isCompleted)
        XCTAssertEqual(groupSession.groupName, "server")
    }

    func testLoadAndFetchGroupSendsServerGroupOnlyWhenCacheIsEmpty() {
        groupSession.clear()
        repository.fetchGroupResponse = .just(makeGroup(name: "server"))

        let recorder = record(sut.loadAndFetchGroup())

        XCTAssertEqual(recorder.values.map(\.groupName), ["server"])
    }

    func testLoadAndFetchGroupKeepsCacheWhenServerFails() {
        repository.fetchGroupResponse = .error(TestError.remote)

        let recorder = record(sut.loadAndFetchGroup())

        XCTAssertEqual(recorder.values.map(\.groupName), ["cached"])
        XCTAssertEqual(recorder.error as? TestError, .remote)
        XCTAssertEqual(groupSession.groupName, "cached")
        XCTAssertEqual(userSession.groupId, "group")
    }

    func testLoadAndFetchGroupClearsGroupIdOnServerAndSessionWhenServerHasNoGroup() {
        repository.fetchGroupResponse = .just(nil)

        let recorder = record(sut.loadAndFetchGroup())

        XCTAssertEqual(recorder.values.map(\.groupName), ["cached"])
        XCTAssertEqual(recorder.error as? FetchError, .notFound)
        XCTAssertNil(groupSession.session)
        // 서버의 groupId도 지워야 다음 유저 조회가 없는 그룹의 id를 되살리지 않습니다.
        XCTAssertEqual(repository.deletedPaths, ["users/user/groupId"])
        XCTAssertNil(userSession.groupId)
        // 유저 세션은 남겨 둡니다. AppCoordinator가 그룹 화면으로 보냅니다.
        XCTAssertNotNil(userSession.session)
    }

    func testLoadAndFetchGroupKeepsGroupIdWhenServerGroupIdDeletionFails() {
        repository.fetchGroupResponse = .just(nil)
        repository.groupIdDeletionResponse = .error(TestError.remote)

        let recorder = record(sut.loadAndFetchGroup())

        XCTAssertEqual(recorder.error as? TestError, .remote)
        XCTAssertNil(groupSession.session)
        // 서버에서 지우지 못하면 세션의 groupId도 남겨 다음 조회에서 다시 정리합니다.
        XCTAssertEqual(userSession.groupId, "group")
    }

    func testLoadAndFetchGroupKeepsNewGroupWhenUserMovedBeforeResponse() {
        // 응답이 오기 전에 다른 그룹에 참여했습니다.
        repository.fetchGroupResponse = .deferred { [userSession] in
            userSession?.update(\.groupId, "other")
            return .just(nil)
        }

        _ = record(sut.loadAndFetchGroup())

        XCTAssertEqual(userSession.groupId, "other")
        XCTAssertNotNil(groupSession.session)
        XCTAssertTrue(repository.deletedPaths.isEmpty)
    }

    func testLoadAndFetchGroupFailsWithoutGroupId() {
        userSession.update(\.groupId, nil)

        let recorder = record(sut.loadAndFetchGroup())

        XCTAssertTrue(recorder.values.isEmpty)
        XCTAssertNotNil(recorder.error)
        XCTAssertEqual(repository.fetchGroupCount, 0)
    }

    // MARK: - 쓰기 후 다시 읽기

    func testDeletePostAndReloadSendsOnceAfterSavingServerGroup() {
        repository.fetchGroupResponse = .just(makeGroup(name: "server"))
        var count = 0
        var isCompleted = false

        sut.deletePostAndReload(post: makePost())
            .subscribe(
                onNext: { count += 1 },
                onCompleted: { isCompleted = true }
            )
            .disposed(by: disposeBag)

        XCTAssertEqual(count, 1)
        XCTAssertTrue(isCompleted)
        XCTAssertEqual(repository.fetchGroupCount, 1)
        XCTAssertEqual(repository.deletedPaths.count, 1)
        XCTAssertEqual(groupSession.groupName, "server")
    }
}

// MARK: - Helpers

private extension GroupUsecaseFetchTests {
    func record(_ observable: Observable<HCGroup>) -> Recorder<HCGroup> {
        let recorder = Recorder<HCGroup>()
        observable
            .subscribe(
                onNext: { recorder.values.append($0) },
                onError: { recorder.error = $0 },
                onCompleted: { recorder.isCompleted = true }
            )
            .disposed(by: disposeBag)
        return recorder
    }

    func makeUser(groupId: String?) -> User {
        User(
            uid: "user",
            registerDate: .now,
            loginPlatform: .kakao,
            nickname: "user",
            birthdayDate: .now,
            gender: .other,
            isPushEnabled: true,
            groupId: groupId
        )
    }

    func makeGroup(name: String) -> HCGroup {
        HCGroup(
            groupId: "group",
            groupName: name,
            createdAt: .now,
            hostUserId: "user",
            inviteCode: "code",
            members: [:],
            postsByDate: [:]
        )
    }

    func makePost() -> Post {
        Post(
            postId: "post",
            userId: "user",
            nickname: "user",
            profileImageURL: nil,
            imageURL: "https://example.com/post.jpg",
            createdAt: .now,
            likeCount: 0,
            comments: [:]
        )
    }
}

/// 구독 결과를 모읍니다.
private final class Recorder<Element> {
    var values: [Element] = []
    var error: Error?
    var isCompleted = false
}

/// 그룹 조회와 게시물·groupId 삭제만 흉내 내는 저장소입니다.
private final class FakeGroupRepository: GroupRepositoryProtocol {
    var fetchGroupResponse: Single<HCGroup?> = .never()
    var groupIdDeletionResponse: Single<Void> = .just(())
    private(set) var fetchGroupCount = 0
    private(set) var deletedPaths: [String] = []

    func fetchGroup(groupId _: String) -> Single<HCGroup?> {
        fetchGroupCount += 1
        return fetchGroupResponse
    }

    func deleteImage(path _: String) -> Single<Void> {
        .just(())
    }

    func deleteValue(path: String) -> Single<Void> {
        if path.hasSuffix("/groupId") {
            return groupIdDeletionResponse.do(onSuccess: { [weak self] in
                self?.deletedPaths.append(path)
            })
        }
        deletedPaths.append(path)
        return .just(())
    }

    func createGroup(groupName _: String) -> Single<(groupId: String, inviteCode: String)> { .never() }
    func joinGroup(inviteCode _: String) -> Single<HCGroup> { .never() }
    func updateGroup(path _: String, post _: Post) -> Single<Void> { .never() }
    func updateBirthdaySettings(groupId _: String, settings _: GroupBirthdaySettings) -> Single<Void> { .never() }
    func updateUserGroupId(groupId _: String) -> Single<Void> { .never() }
    func uploadImage(image _: UIImage, path _: String) -> Single<URL> { .never() }
    func addComment(path _: String, value _: Comment) -> Single<Void> { .never() }
    func deleteComment(path _: String) -> Single<Void> { .never() }
    func observeValueStream<T: Decodable>(path _: String, type _: T.Type) -> Observable<T> { .never() }
}
