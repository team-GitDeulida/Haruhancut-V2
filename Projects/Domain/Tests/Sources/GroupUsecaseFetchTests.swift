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

        let recorder = record(sut.loadAndFetchGroup())

        // 늦게 온 응답은 버리고 끝납니다.
        XCTAssertEqual(recorder.values.map(\.groupName), ["cached"])
        XCTAssertTrue(recorder.isCompleted)
        XCTAssertEqual(userSession.groupId, "other")
        XCTAssertNotNil(groupSession.session)
        XCTAssertTrue(repository.deletedPaths.isEmpty)
    }

    func testLoadAndFetchGroupDoesNotSaveLateGroupAfterUserMoved() {
        // 응답이 오기 전에 다른 그룹에 참여해 새 그룹을 저장했습니다.
        repository.fetchGroupResponse = .deferred { [userSession, groupSession] in
            userSession?.update(\.groupId, "other")
            groupSession?.update(self.makeGroup(name: "other").toSession())
            return .just(self.makeGroup(name: "server"))
        }

        let recorder = record(sut.loadAndFetchGroup())

        // 예전 그룹의 응답을 저장하지도, 화면에 보내지도 않습니다.
        XCTAssertEqual(recorder.values.map(\.groupName), ["cached"])
        XCTAssertTrue(recorder.isCompleted)
        XCTAssertEqual(groupSession.groupName, "other")
    }

    func testLoadAndFetchGroupFailsWithoutGroupId() {
        userSession.update(\.groupId, nil)

        let recorder = record(sut.loadAndFetchGroup())

        XCTAssertTrue(recorder.values.isEmpty)
        XCTAssertNotNil(recorder.error)
        XCTAssertEqual(repository.fetchGroupCount, 0)
    }

    // MARK: - 구독·단계·요청 합치기

    func testObserveGroupSendsStoredGroupAndChangesWithoutServer() {
        var names: [String] = []
        sut.observeGroup()
            .subscribe(onNext: { names.append($0.groupName) })
            .disposed(by: disposeBag)

        groupSession.update(makeGroup(name: "changed").toSession())
        // 같은 그룹을 다시 저장해도 다시 보내지 않습니다.
        groupSession.update(makeGroup(name: "changed").toSession())

        XCTAssertEqual(names, ["cached", "changed"])
        XCTAssertEqual(repository.fetchGroupCount, 0)
    }

    func testFetchGroupResultSendsLoadingThenSuccess() {
        repository.fetchGroupResponse = .just(makeGroup(name: "server"))
        var steps: [String] = []

        sut.fetchGroupResult()
            .subscribe(onNext: { result in
                steps.append("\(result.status)-\(result.value?.groupName ?? "nil")")
            })
            .disposed(by: disposeBag)

        XCTAssertEqual(steps, ["loading-cached", "success-server"])
    }

    func testLoadAndFetchGroupSharesOneRequestWhenCalledTogether() {
        let response = PublishSubject<HCGroup?>()
        repository.fetchGroupResponse = response.take(1).asSingle()
        let first = record(sut.loadAndFetchGroup())
        let second = record(sut.loadAndFetchGroup())

        response.onNext(makeGroup(name: "server"))

        XCTAssertEqual(repository.fetchGroupCount, 1)
        XCTAssertEqual(first.values.map(\.groupName), ["cached", "server"])
        XCTAssertEqual(second.values.map(\.groupName), ["cached", "server"])
    }

    func testLoadAndFetchGroupSkipsServerRightAfterReceivingGroup() {
        repository.fetchGroupResponse = .just(makeGroup(name: "server"))
        _ = record(sut.loadAndFetchGroup())

        let recorder = record(sut.loadAndFetchGroup())

        XCTAssertEqual(repository.fetchGroupCount, 1)
        XCTAssertEqual(recorder.values.map(\.groupName), ["server"])
        XCTAssertTrue(recorder.isCompleted)
    }

    func testRefreshGroupResultAsksServerEvenRightAfterReceivingGroup() {
        repository.fetchGroupResponse = .just(makeGroup(name: "server"))
        _ = record(sut.loadAndFetchGroup())

        sut.refreshGroupResult()
            .subscribe()
            .disposed(by: disposeBag)

        XCTAssertEqual(repository.fetchGroupCount, 2)
    }

    // MARK: - 쓰기 (먼저 바꾸고, 실패하면 되돌리기)

    func testDeletePostRemovesPostFromStoredGroupWithoutServerRead() {
        let post = makePost()
        groupSession.update(makeGroup(name: "cached", posts: [post]).toSession())
        var count = 0
        var isCompleted = false

        sut.deletePostAndReload(post: post)
            .subscribe(
                onNext: { count += 1 },
                onCompleted: { isCompleted = true }
            )
            .disposed(by: disposeBag)

        XCTAssertEqual(count, 1)
        XCTAssertTrue(isCompleted)
        XCTAssertEqual(repository.fetchGroupCount, 0)
        XCTAssertEqual(repository.deletedPaths.count, 1)
        XCTAssertTrue(storedPosts().isEmpty)
    }

    func testDeletePostRestoresPostWhenServerDeletionFails() {
        let post = makePost()
        groupSession.update(makeGroup(name: "cached", posts: [post]).toSession())
        repository.postDeletionResponse = .error(TestError.remote)
        var error: Error?

        sut.deletePostAndReload(post: post)
            .subscribe(onError: { error = $0 })
            .disposed(by: disposeBag)

        XCTAssertEqual(error as? TestError, .remote)
        XCTAssertEqual(storedPosts().map(\.postId), [post.postId])
    }

    func testAddCommentShowsCommentBeforeServerResponds() {
        let post = makePost()
        groupSession.update(makeGroup(name: "cached", posts: [post]).toSession())
        let write = PublishSubject<Void>()
        repository.addCommentResponse = write.take(1).asSingle()

        sut.addComment(post: post, text: "hello")
            .subscribe()
            .disposed(by: disposeBag)

        XCTAssertEqual(storedPosts().first?.comments.values.map(\.text), ["hello"])
        XCTAssertEqual(repository.addedCommentPaths.count, 1)
    }

    func testAddCommentWritesThenSavesServerGroupWhenNoGroupIsStored() {
        groupSession.clear()
        repository.fetchGroupResponse = .just(makeGroup(name: "server", posts: [makePost()]))
        var isSucceeded = false

        sut.addComment(post: makePost(), text: "hello")
            .subscribe(onSuccess: { isSucceeded = true })
            .disposed(by: disposeBag)

        // 바꿀 캐시가 없으면 서버에 쓰고 서버 그룹을 받아 저장합니다.
        XCTAssertTrue(isSucceeded)
        XCTAssertEqual(repository.addedCommentPaths.count, 1)
        XCTAssertEqual(repository.fetchGroupCount, 1)
        XCTAssertEqual(groupSession.entity?.groupName, "server")
    }

    func testAddCommentSavesServerGroupWhenPostIsNotStored() {
        let comment = Comment(
            commentId: "comment",
            userId: "user",
            nickname: "user",
            profileImageURL: nil,
            text: "hello",
            createdAt: .now
        )
        var serverPost = makePost()
        serverPost.comments = ["comment": comment]
        repository.fetchGroupResponse = .just(makeGroup(name: "server", posts: [serverPost]))

        // 저장된 그룹에는 아직 이 게시물이 없습니다.
        sut.addComment(post: makePost(), text: "hello")
            .subscribe()
            .disposed(by: disposeBag)

        XCTAssertEqual(repository.fetchGroupCount, 1)
        XCTAssertEqual(storedPosts().first?.comments.values.map(\.text), ["hello"])
    }

    func testAddCommentDoesNotChangeStoredGroupOfAnotherGroup() {
        // 그룹 참여 직후처럼 세션은 새 그룹을 가리키는데 이전 그룹이 저장돼 있습니다.
        let post = makePost()
        groupSession.update(makeGroup(id: "old-group", name: "old", posts: [post]).toSession())
        repository.fetchGroupResponse = .just(makeGroup(name: "server", posts: [post]))

        sut.addComment(post: post, text: "hello")
            .subscribe()
            .disposed(by: disposeBag)

        // 이전 그룹에 댓글을 넣지 않고, 서버에 쓴 뒤 새 그룹을 받아 저장합니다.
        XCTAssertEqual(repository.addedCommentPaths.first?.hasPrefix("groups/group/"), true)
        XCTAssertEqual(repository.fetchGroupCount, 1)
        XCTAssertEqual(groupSession.entity?.groupId, "group")
        XCTAssertEqual(groupSession.entity?.groupName, "server")
    }

    func testAddCommentSucceedsWhenGroupReloadAfterWriteFails() {
        groupSession.clear()
        repository.fetchGroupResponse = .error(TestError.remote)
        var isSucceeded = false

        sut.addComment(post: makePost(), text: "hello")
            .subscribe(onSuccess: { isSucceeded = true })
            .disposed(by: disposeBag)

        // 서버 쓰기는 끝났으므로 다시 받기가 실패해도 성공입니다.
        XCTAssertTrue(isSucceeded)
    }

    func testDeletePostDeletesOnServerThenSavesServerGroupWhenNoGroupIsStored() {
        groupSession.clear()
        repository.fetchGroupResponse = .just(makeGroup(name: "server"))
        var isCompleted = false

        sut.deletePostAndReload(post: makePost())
            .subscribe(onCompleted: { isCompleted = true })
            .disposed(by: disposeBag)

        XCTAssertTrue(isCompleted)
        XCTAssertEqual(repository.deletedPaths.count, 1)
        XCTAssertEqual(groupSession.entity?.groupName, "server")
    }

    func testAddCommentRemovesCommentWhenServerFails() {
        let post = makePost()
        groupSession.update(makeGroup(name: "cached", posts: [post]).toSession())
        repository.addCommentResponse = .error(TestError.remote)
        var error: Error?

        sut.addComment(post: post, text: "hello")
            .subscribe(onFailure: { error = $0 })
            .disposed(by: disposeBag)

        XCTAssertEqual(error as? TestError, .remote)
        XCTAssertEqual(storedPosts().first?.comments.isEmpty, true)
    }

    // MARK: - 생일 설정 (먼저 바꾸고, 실패하면 되돌리기)

    func testUpdateBirthdaySettingsChangesStoredGroupBeforeServerResponds() {
        storeGroupWithMe()
        let write = PublishSubject<Void>()
        repository.birthdaySettingsResponse = write.take(1).asSingle()
        let settings = GroupBirthdaySettings(isEnabled: false, calendarMode: .solar)

        sut.updateBirthdaySettings(settings)
            .subscribe()
            .disposed(by: disposeBag)

        XCTAssertEqual(groupSession.entity?.birthdaySettings, settings)
        XCTAssertEqual(repository.updatedBirthdaySettings, [settings])
    }

    func testUpdateBirthdaySettingsRestoresStoredGroupWhenServerFails() {
        storeGroupWithMe()
        repository.birthdaySettingsResponse = .error(TestError.remote)
        var error: Error?

        sut.updateBirthdaySettings(GroupBirthdaySettings(isEnabled: false, calendarMode: .solar))
            .subscribe(onFailure: { error = $0 })
            .disposed(by: disposeBag)

        XCTAssertEqual(error as? TestError, .remote)
        XCTAssertNil(groupSession.entity?.birthdaySettings)
    }

    func testDeleteCommentRestoresCommentWhenServerFails() {
        let comment = Comment(
            commentId: "comment",
            userId: "user",
            nickname: "user",
            profileImageURL: nil,
            text: "hello",
            createdAt: .now
        )
        var post = makePost()
        post.comments = ["comment": comment]
        groupSession.update(makeGroup(name: "cached", posts: [post]).toSession())
        repository.deleteCommentResponse = .error(TestError.remote)

        sut.deleteComment(post: post, commentId: "comment")
            .subscribe()
            .disposed(by: disposeBag)

        XCTAssertEqual(storedPosts().first?.comments["comment"], comment)
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

    func makeGroup(id: String = "group", name: String, posts: [Post] = []) -> HCGroup {
        HCGroup(
            groupId: id,
            groupName: name,
            createdAt: Date(timeIntervalSince1970: 0),
            hostUserId: "user",
            inviteCode: "code",
            members: [:],
            postsByDate: posts.isEmpty ? [:] : [Date.now.toDateKey(): posts]
        )
    }

    /// 생일 설정을 바꿀 수 있도록 내가 멤버인 그룹을 저장합니다.
    func storeGroupWithMe() {
        var group = makeGroup(name: "cached")
        group.members = ["user": "joined"]
        groupSession.update(group.toSession())
    }

    func storedPosts() -> [Post] {
        groupSession.postsByDate.values.flatMap { $0 }
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
    var postDeletionResponse: Single<Void> = .just(())
    var addCommentResponse: Single<Void> = .just(())
    var deleteCommentResponse: Single<Void> = .just(())
    var birthdaySettingsResponse: Single<Void> = .just(())
    private(set) var updatedBirthdaySettings: [GroupBirthdaySettings] = []
    private(set) var fetchGroupCount = 0
    private(set) var deletedPaths: [String] = []
    private(set) var addedCommentPaths: [String] = []

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
        return postDeletionResponse.do(onSuccess: { [weak self] in
            self?.deletedPaths.append(path)
        })
    }

    func createGroup(groupName _: String) -> Single<(groupId: String, inviteCode: String)> { .never() }
    func joinGroup(inviteCode _: String) -> Single<HCGroup> { .never() }
    func updateGroup(path _: String, post _: Post) -> Single<Void> { .never() }
    func updateBirthdaySettings(groupId _: String, settings: GroupBirthdaySettings) -> Single<Void> {
        updatedBirthdaySettings.append(settings)
        return birthdaySettingsResponse
    }
    func updateUserGroupId(groupId _: String) -> Single<Void> { .never() }
    func uploadImage(image _: UIImage, path _: String) -> Single<URL> { .never() }
    func addComment(path: String, value _: Comment) -> Single<Void> {
        addedCommentPaths.append(path)
        return addCommentResponse
    }

    func deleteComment(path _: String) -> Single<Void> {
        deleteCommentResponse
    }
    func observeValueStream<T: Decodable>(path _: String, type _: T.Type) -> Observable<T> { .never() }
}
