//
//  CollectionViewAdapter+SectionReachedEnd.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/27/26.
//

import UIKit

/// 하나의 Section 끝 접근 callback 전달 상태입니다.
final class CollectionViewAdapterSectionReachedEndState {
    let threshold: CollectionViewReachedEndThreshold
    var isInsideThreshold = false
    var isDeliveryScheduled = false

    init(
        threshold: CollectionViewReachedEndThreshold
    ) {
        self.threshold = threshold
    }
}

/// Section별 끝 접근 설정과 전달 상태를 보관합니다.
final class CollectionViewAdapterSectionReachedEndCallbacks {
    var configurations:
        [
            AnyHashable:
                SectionReachedEndConfiguration
        ] = [:]
    var states:
        [
            AnyHashable:
                CollectionViewAdapterSectionReachedEndState
        ] = [:]
}

extension CollectionViewAdapter {
    /// 새 Section tree에 맞춰 callback 설정과 전달 상태를 동기화합니다.
    func updateSectionReachedEndConfigurations(
        _ sections: [ResolvedSection]
    ) {
        let configurations = Dictionary(
            uniqueKeysWithValues:
                sections.compactMap { section in
                    section.reachedEnd.map {
                        (
                            section.identifier,
                            $0
                        )
                    }
                }
        )
        let activeIdentifiers =
            Set(configurations.keys)

        sectionReachedEndCallbacks
            .configurations = configurations
        sectionReachedEndCallbacks.states =
            sectionReachedEndCallbacks.states
                .filter {
                    activeIdentifiers.contains(
                        $0.key
                    )
                }

        for (
            identifier,
            configuration
        ) in configurations {
            guard
                sectionReachedEndCallbacks
                    .states[identifier]?
                    .threshold
                    == configuration.threshold
            else {
                sectionReachedEndCallbacks
                    .states[identifier] =
                        CollectionViewAdapterSectionReachedEndState(
                            threshold:
                                configuration
                                    .threshold
                        )
                continue
            }
        }
    }

    /// 가로 Section이 threshold 영역에 새로 진입하면 callback을 예약합니다.
    func triggerSectionReachedEndIfNeeded(
        sectionIdentifier: AnyHashable,
        metrics:
            CollectionViewSectionScrollMetrics
    ) {
        guard
            let configuration =
                sectionReachedEndCallbacks
                    .configurations[
                        sectionIdentifier
                    ],
            let state =
                sectionReachedEndCallbacks
                    .states[sectionIdentifier],
            metrics.viewportLength > 0
        else {
            return
        }

        let triggerDistance: CGFloat
        switch configuration.threshold {
        case let .absolute(distance):
            triggerDistance = max(0, distance)
        case let .relativeToViewport(multiplier):
            triggerDistance =
                metrics.viewportLength
                * max(0, multiplier)
        }

        guard
            metrics.remainingDistance
                <= triggerDistance
        else {
            state.isInsideThreshold = false
            return
        }

        guard !state.isInsideThreshold else {
            return
        }

        state.isInsideThreshold = true
        scheduleSectionReachedEndDelivery(
            sectionIdentifier:
                sectionIdentifier,
            state: state
        )
    }

    /// UIKit layout 갱신이 끝난 다음 MainActor 실행 차례에 callback을 전달합니다.
    private func scheduleSectionReachedEndDelivery(
        sectionIdentifier: AnyHashable,
        state:
            CollectionViewAdapterSectionReachedEndState
    ) {
        guard !state.isDeliveryScheduled else {
            return
        }

        state.isDeliveryScheduled = true
        Task { @MainActor [weak self] in
            await Task.yield()
            guard
                let self,
                let currentState =
                    sectionReachedEndCallbacks
                        .states[
                            sectionIdentifier
                        ],
                currentState === state
            else {
                return
            }

            currentState.isDeliveryScheduled =
                false
            sectionReachedEndCallbacks
                .configurations[
                    sectionIdentifier
                ]?
                .action()
        }
    }
}
