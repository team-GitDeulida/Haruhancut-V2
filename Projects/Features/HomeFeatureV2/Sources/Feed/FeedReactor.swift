//
//  FeedReactor.swift
//  HomeFeatureV2
//
//  Created by 김동현 on 4/21/26.
//

import UIKit
import ReactorKit
import Core
import Domain

final class FeedReactor: Reactor {
    @Dependency private var userSession: UserSession
    @Dependency private var authUsecase: AuthUsecaseProtocol
    private let groupLoader: HomeGroupLoader
    private let groupUsecase:
        GroupUsecaseProtocol?
    private let widgetUsecase:
        WidgetUsecaseProtocol?
    /// 서버 응답을 기다리는 게시물 삭제 수입니다. 0보다 크면 위젯을 맞추지 않습니다.
    private var deletingPostCount = 0
    /// 삭제 중이라 위젯 맞추기를 건너뛰었는지입니다. 모든 삭제가 끝나면 한 번에 맞춥니다.
    private var hasSkippedWidgetSync = false
    /// 마지막으로 받은 그룹의 게시물입니다. 삭제가 끝난 뒤 위젯을 맞출 때 씁니다.
    private var latestPostsByDate: [String: [Post]]?

    enum Action {
        case viewDidLoad
        case refresh
        case deleteConfirmed(Post)
        case viewDidAppear
    }

    enum Mutation {
        case setUser(User)
        case setLoading(Bool)
        case setFeed(
            components: [FeedComponent],
            didTodayUpload: Bool
        )
        case notifyLoadFailure
    }

    struct State {
        var user: User?
        var isLoading: Bool = false
        var components: [FeedComponent] = []
        var didTodayUpload: Bool = false
        /// 서버에서 최신 피드를 받지 못했을 때 한 번 알립니다.
        @Pulse var loadFailure: Void?
    }

    let initialState = State()

    /// - Parameters:
    ///   - groupLoader: 표시할 그룹을 조회하고 저장된 그룹의 변화를 구독하는 방법.
    ///   - groupUsecase: 게시물 삭제에 쓰는 Usecase. 읽기 전용 화면에서는 `nil`입니다.
    ///   - widgetUsecase: 홈 화면 위젯 저장소를 맞추는 Usecase. 내 그룹을 표시할 때만 전달합니다.
    init(
        groupLoader: HomeGroupLoader,
        groupUsecase:
            GroupUsecaseProtocol?,
        widgetUsecase:
            WidgetUsecaseProtocol? = nil
    ) {
        self.groupLoader = groupLoader
        self.groupUsecase =
            groupUsecase
        self.widgetUsecase =
            widgetUsecase
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidAppear:
            return loadFeed(force: false)
        case .viewDidLoad:
            return loadFeed(force: false)
        case .refresh:
            // 당겨서 새로고침하면 최근에 받은 그룹이 있어도 서버에 묻는다
            return loadFeed(force: true)
        case .deleteConfirmed(let post):
            return deletePost(post)
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch mutation {
        case .setUser(let user):
            state.user = user
        case .setLoading(let isLoading):
            state.isLoading = isLoading
        case .setFeed(let components, let didTodayUpload):
            state.components = components
            state.didTodayUpload = didTodayUpload
        case .notifyLoadFailure:
            state.loadFailure = ()
        }
        return state
    }

    /// 저장된 그룹이 바뀌면(업로드·삭제·댓글, 다른 화면의 조회) 피드와 위젯을 다시 맞춥니다.
    ///
    /// 관리자 미리보기는 저장된 그룹이 없어 아무것도 보내지 않습니다.
    func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
        let storedGroupChanges = groupLoader.changes()
            .do(onNext: { [weak self] group in
                self?.synchronizeWidget(postsByDate: group.postsByDate)
            })
            .withUnretained(self)
            .map { owner, group in
                owner.makeFeedMutation(from: group.postsByDate)
            }
            .catch { error in
                Logger.e("FeedReactor observeGroup failed: \(error)")
                return .empty()
            }
        return .merge(mutation, storedGroupChanges)
    }
}

private extension FeedReactor {
    func loadFeed(force: Bool) -> Observable<Mutation> {
        let loadUser: Observable<Mutation> = authUsecase
            .loadAndFetchUser()
            .map(Mutation.setUser)
            .catch { error in
                Logger.e("FeedReactor loadAndFetchUser failed: \(error)")
                return .empty()
            }
            .asObservable()

        // 조회가 어떻게 끝나든(성공·실패·응답 버림) 로딩을 끈다
        let loadGroup: Observable<Mutation> = Observable.concat([
            .just(.setLoading(true)),
            groupLoader
                .fetch(force)
                .do(onNext: { [weak self] result in
                    // 날짜가 바뀌면 같은 그룹이어도 위젯에 보일 사진이 달라지므로 조회가 끝날 때마다 맞춘다.
                    // 그룹 구독은 같은 그룹을 다시 보내지 않는다
                    guard case .success = result.status, let group = result.value else { return }
                    self?.synchronizeWidget(postsByDate: group.postsByDate)
                })
                .withUnretained(self)
                .flatMap { owner, result in
                    Observable.from(owner.mutations(for: result))
                }
                .catch { error in
                    Logger.e("FeedReactor fetchGroup failed: \(error)")
                    return .just(.notifyLoadFailure)
                },
            .just(.setLoading(false))
        ])

        return Observable.merge([loadUser, loadGroup])
    }

    /// 조회 단계를 피드 상태로 바꿉니다. 로딩 표시는 `loadFeed(force:)`가 조회 앞뒤로 켜고 끕니다.
    ///
    /// - `.loading`, `.success`: 값이 있으면 그 그룹으로 그립니다.
    /// - `.failure`: 캐시는 그대로 두고 실패를 알립니다.
    /// - `.notFound`: 따로 할 일이 없습니다. 세션이 지워져 AppCoordinator가 화면을 바꿉니다.
    func mutations(for result: FetchResult<HCGroup>) -> [Mutation] {
        var mutations: [Mutation] = []
        // 관리자 미리보기는 저장된 그룹 구독이 없으므로 조회 결과로 피드를 그린다
        if let group = result.value {
            mutations.append(makeFeedMutation(from: group.postsByDate))
        }

        if case let .failure(error) = result.status {
            Logger.e("FeedReactor fetchGroup failed: \(error)")
            mutations.append(.notifyLoadFailure)
        }
        return mutations
    }

    /// 게시물을 지웁니다.
    ///
    /// 저장된 그룹에서 먼저 빠지므로 피드는 그룹 구독으로 바로 바뀝니다.
    /// 서버 삭제가 실패하면 저장된 그룹이 되돌아가고 피드도 따라 돌아옵니다.
    /// 위젯은 기존처럼 서버에서 지워진 뒤에 맞춥니다. 삭제가 겹치면 모두 끝난 뒤 마지막 그룹으로 한 번에 맞춰서,
    /// 먼저 끝난 삭제가 아직 서버에서 지워지지 않은 게시물까지 위젯에서 빼지 않게 합니다.
    func deletePost(_ post: Post) -> Observable<Mutation> {
        guard
            let groupUsecase
        else {
            return .empty()
        }

        let deletion = Observable<Void>
            .deferred { [weak self] in
                self?.deletingPostCount += 1
                return groupUsecase
                    .deletePostAndReload(post: post)
                    .take(1)
            }
            .do(
                onNext: { [weak self] _ in
                    // 서버에서 지워진 뒤에 내려받던 위젯 사진을 저장하지 않게 한다
                    self?.widgetUsecase?.removePhoto(of: post)
                },
                onDispose: { [weak self] in
                    self?.finishDeletingPost()
                }
            )
            .flatMap { _ in Observable<Mutation>.empty() }
            .catch { error in
                Logger.e(
                    "FeedReactor deletePostAndReload failed: \(error)"
                )
                return .empty()
            }

        return Observable.concat([
            .just(.setLoading(true)),
            deletion,
            .just(.setLoading(false))
        ])
    }

    /// 위젯을 맞춥니다. 게시물을 지우는 중에는 건너뛰고, 모든 삭제가 끝난 뒤에 맞춥니다.
    func synchronizeWidget(postsByDate: [String: [Post]]) {
        latestPostsByDate = postsByDate
        guard deletingPostCount == 0 else {
            hasSkippedWidgetSync = true
            return
        }
        widgetUsecase?.synchronize(postsByDate: postsByDate)
    }

    /// 삭제 하나가 끝났습니다(성공·실패). 모든 삭제가 끝났고 건너뛴 위젯 맞추기가 있으면 마지막 그룹으로 맞춥니다.
    func finishDeletingPost() {
        deletingPostCount -= 1
        guard
            deletingPostCount == 0,
            hasSkippedWidgetSync,
            let postsByDate = latestPostsByDate
        else {
            return
        }
        hasSkippedWidgetSync = false
        widgetUsecase?.synchronize(postsByDate: postsByDate)
    }

    func makeFeedMutation(from postsByDate: [String: [Post]]) -> Mutation {
        let components = Self.makeComponents(from: postsByDate)
        return .setFeed(
            components: components,
            didTodayUpload: Self.didTodayUpload(
                in: components,
                currentUserID: userSession.userId
            )
        )
    }
}

extension FeedReactor {
    static func makeComponents(
        from postsByDate: [String: [Post]]
    ) -> [FeedComponent] {
        postsByDate.values
            .flatMap { $0 }
            .sorted { $0.createdAt > $1.createdAt }
            .filter { $0.isToday }
            .map { FeedComponent(post: $0) }
    }

    static func didTodayUpload(
        in components: [FeedComponent],
        currentUserID: String?
    ) -> Bool {
        guard let currentUserID else { return false }
        return components.contains {
            $0.post.userId == currentUserID
        }
    }
}
