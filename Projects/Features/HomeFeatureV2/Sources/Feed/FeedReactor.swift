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
    @Dependency private var groupSession: GroupSession
    @Dependency private var authUsecase: AuthUsecaseProtocol
    private let loadGroup:
        () -> Observable<HCGroup>
    private let groupUsecase:
        GroupUsecaseProtocol?

    enum Action {
        case viewDidLoad
        case refresh
        case deleteConfirmed(Post)
        case viewDidAppear
    }

    enum Mutation {
        case setUser(User)
        case setLoading(Bool)
        case setComponents([FeedComponent])
    }

    struct State {
        var user: User?
        var isLoading: Bool = false
        var components: [FeedComponent] = []
    }

    let initialState = State()

    init(
        loadGroup:
            @escaping () -> Observable<HCGroup>,
        groupUsecase:
            GroupUsecaseProtocol?
    ) {
        self.loadGroup = loadGroup
        self.groupUsecase =
            groupUsecase
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidAppear:
            return loadFeed()
        case .viewDidLoad:
            return loadFeed()
        case .refresh:
            return loadFeed()
            /*
            Observable.just(())
                .delay(.seconds(1), scheduler: MainScheduler.instance)
                .flatMap { self.loadFeed() }
             */
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
        case .setComponents(let components):
            state.components = components
        }
        return state
    }
}

private extension FeedReactor {
    func loadFeed() -> Observable<Mutation> {
        Observable.concat([
            .just(.setLoading(true)),
            reloadFeed(),
            .just(.setLoading(false))
        ])
    }

    func deletePost(_ post: Post) -> Observable<Mutation> {
        guard
            let groupUsecase
        else {
            return .empty()
        }
        let previousComponents = currentState.components
        let remainingComponents = previousComponents.filter {
            $0.post.postId != post.postId
        }

        let synchronizeDeletion = groupUsecase
            .deletePostAndReload(post: post)
            .takeLast(1)
            .flatMap { [weak self] _ -> Observable<Mutation> in
                guard let self else { return .empty() }
                return .just(
                    .setComponents(
                        self.makeComponents(
                            from: self.groupSession.postsByDate
                        )
                    )
                )
            }
            .catch { error in
                Logger.e(
                    "FeedReactor deletePostAndReload failed: \(error)"
                )
                return .just(
                    .setComponents(previousComponents)
                )
            }

        return Observable.concat([
            .just(.setLoading(true)),
            .just(.setComponents(remainingComponents)),
            synchronizeDeletion,
            .just(.setLoading(false))
        ])
    }

    func reloadFeed() -> Observable<Mutation> {
        let loadUser: Observable<Mutation> = authUsecase
            .loadAndFetchUser()
            .map(Mutation.setUser)
            .catch { error in
                Logger.e("FeedReactor loadAndFetchUser failed: \(error)")
                return .empty()
            }
            .asObservable()

        let loadGroup: Observable<Mutation> =
            loadGroup()
            .map { group -> Mutation in
                Mutation.setComponents(self.makeComponents(from: group.postsByDate))
            }
            .catch { error in
                Logger.e("FeedReactor loadAndFetchGroup failed: \(error)")
                return .empty()
            }
            .asObservable()

        return Observable.merge([loadUser, loadGroup])
    }

    func makeComponents(from postsByDate: [String: [Post]]) -> [FeedComponent] {
        postsByDate.values
            .flatMap { $0 }
            .sorted { $0.createdAt > $1.createdAt }
            .filter { $0.isToday }
            .map { FeedComponent(post: $0) }
    }
}
