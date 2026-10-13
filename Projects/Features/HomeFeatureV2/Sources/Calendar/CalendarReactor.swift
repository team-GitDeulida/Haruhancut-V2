//
//  CalendarReactor.swift
//  HomeFeatureV2
//
//  Created by 김동현 on 4/21/26.
//

import UIKit
import ReactorKit
import Core
import Domain

final class CalendarReactor: Reactor {
    private let groupLoader: HomeGroupLoader

    enum Action {
        case viewDidAppear
    }

    enum Mutation {
        case setPostsByDate([String: [Post]])
    }

    struct State {
        var postsByDate: [String: [Post]] = [:]
    }

    let initialState = State()

    /// - Parameter groupLoader: 표시할 그룹을 조회하고 저장된 그룹의 변화를 구독하는 방법.
    init(
        groupLoader: HomeGroupLoader
    ) {
        self.groupLoader =
            groupLoader
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidAppear:
            return loadCalendar()
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch mutation {
        case .setPostsByDate(let postsByDate):
            state.postsByDate = postsByDate
        }
        return state
    }

    /// 저장된 그룹이 바뀌면(피드에서 업로드·삭제 등) 다시 조회하지 않고 캘린더를 다시 그립니다.
    func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
        let storedGroupChanges = groupLoader.changes()
            .map { Mutation.setPostsByDate($0.postsByDate) }
            .catch { error in
                Logger.e("CalendarReactor observeGroup failed: \(error)")
                return .empty()
            }
        return .merge(mutation, storedGroupChanges)
    }
}

private extension CalendarReactor {
    func loadCalendar() -> Observable<Mutation> {
        groupLoader.values()
            .map { Mutation.setPostsByDate($0.postsByDate) }
            .catch { error in
                Logger.e("CalendarReactor loadAndFetchGroup failed: \(error)")
                return .empty()
            }
    }
}
