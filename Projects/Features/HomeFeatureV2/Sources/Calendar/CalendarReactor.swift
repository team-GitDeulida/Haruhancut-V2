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
    @Dependency private var groupUsecase: GroupUsecaseProtocol

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
}

private extension CalendarReactor {
    func loadCalendar() -> Observable<Mutation> {
        groupUsecase
            .loadAndFetchGroup()
            .map { Mutation.setPostsByDate($0.postsByDate) }
            .catch { error in
                Logger.e("CalendarReactor loadAndFetchGroup failed: \(error)")
                return .empty()
            }
    }
}
