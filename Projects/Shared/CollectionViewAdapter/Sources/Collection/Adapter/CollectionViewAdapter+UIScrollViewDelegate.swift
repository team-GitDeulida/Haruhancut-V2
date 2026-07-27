//
//  CollectionViewAdapter+UIScrollViewDelegate.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/26/26.
//

import UIKit

/// CollectionView 끝에 접근했다고 판단할 거리를 표현합니다.
public enum CollectionViewReachedEndThreshold: Hashable {
    /// 끝에서 지정한 point만큼 남았을 때 알립니다.
    case absolute(CGFloat)

    /// 끝에서 현재 viewport 길이의 지정한 배수만큼 남았을 때 알립니다.
    case relativeToViewport(CGFloat)
}

/// Scroll 위치 기반 공개 callback과 예약 상태를 보관합니다.
final class CollectionViewAdapterScrollCallbacks {
    /// 끝 접근 판단에 사용할 거리입니다.
    var reachedEndThreshold:
        CollectionViewReachedEndThreshold =
            .relativeToViewport(1.5)

    /// 끝 접근 시 실행할 callback입니다.
    var reachedEnd: (() -> Void)?

    /// 동일한 MainActor 실행 차례의 중복 callback 예약을 방지합니다.
    var isReachedEndDeliveryScheduled = false

    /// 끝 접근 영역에 진입한 상태인지 나타냅니다.
    ///
    /// 영역을 벗어나기 전까지 `reachedEnd`가 다시 실행되지 않도록 합니다.
    var isInsideReachedEndThreshold = false
}

extension CollectionViewAdapter {
    /// CollectionView 끝 접근 판단에 사용할 거리입니다.
    ///
    /// `.relativeToViewport(1.5)`는 현재 화면 길이의 1.5배만큼 남았을 때
    /// `reachedEnd`를 실행합니다. 음수는 0으로 처리합니다.
    public var reachedEndThreshold:
        CollectionViewReachedEndThreshold
    {
        get {
            scrollCallbacks.reachedEndThreshold
        }
        set {
            scrollCallbacks.reachedEndThreshold =
                newValue
            scrollCallbacks.isInsideReachedEndThreshold =
                false
        }
    }

    /// CollectionView 끝에 접근했을 때 실행할 동작입니다.
    ///
    /// 설정한 threshold 영역에 진입할 때 한 번 실행되며, 영역을 벗어났다가
    /// 다시 진입하면 다음 callback을 전달합니다.
    ///
    /// `nil`이면 거리 계산을 생략합니다. UIKit의 visible view 갱신과
    /// Diffable snapshot 적용이 겹치지 않도록 callback은 현재
    /// UIScrollViewDelegate 호출이 반환된 다음 MainActor 실행 차례에
    /// 전달됩니다.
    public var reachedEnd: (() -> Void)? {
        get {
            scrollCallbacks.reachedEnd
        }
        set {
            scrollCallbacks.reachedEnd = newValue
            scrollCallbacks.isInsideReachedEndThreshold =
                false
        }
    }

    /// 현재 scroll 위치를 기준으로 끝 접근 여부를 검사합니다.
    public func scrollViewDidScroll(
        _ scrollView: UIScrollView
    ) {
        triggerReachedEndIfNeeded(
            scrollView: scrollView,
            contentOffset: scrollView.contentOffset
        )
    }

    /// 예상 정지 위치를 기준으로 끝 접근 여부를 미리 검사합니다.
    public func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset:
            UnsafeMutablePointer<CGPoint>
    ) {
        triggerReachedEndIfNeeded(
            scrollView: scrollView,
            contentOffset: targetContentOffset.pointee
        )
    }

    /// threshold 영역에 새로 진입했으면 callback 전달을 예약합니다.
    private func triggerReachedEndIfNeeded(
        scrollView: UIScrollView,
        contentOffset: CGPoint
    ) {
        guard
            let collectionView,
            scrollView === collectionView,
            scrollCallbacks.reachedEnd != nil,
            !collectionView.bounds.isEmpty
        else {
            return
        }

        let viewportLength: CGFloat
        let remainingDistance: CGFloat

        if scrollDirection(of: collectionView)
            == .horizontal
        {
            viewportLength = max(
                0,
                collectionView.bounds.width
                    - collectionView
                        .adjustedContentInset.left
                    - collectionView
                        .adjustedContentInset.right
            )
            let visibleEnd =
                contentOffset.x
                + collectionView.bounds.width
                - collectionView
                    .adjustedContentInset.right
            remainingDistance =
                collectionView.contentSize.width
                - visibleEnd
        } else {
            viewportLength = max(
                0,
                collectionView.bounds.height
                    - collectionView
                        .adjustedContentInset.top
                    - collectionView
                        .adjustedContentInset.bottom
            )
            let visibleEnd =
                contentOffset.y
                + collectionView.bounds.height
                - collectionView
                    .adjustedContentInset.bottom
            remainingDistance =
                collectionView.contentSize.height
                - visibleEnd
        }

        guard viewportLength > 0 else {
            return
        }

        let triggerDistance: CGFloat
        switch scrollCallbacks.reachedEndThreshold {
        case .absolute(let distance):
            triggerDistance = max(0, distance)
        case .relativeToViewport(let multiplier):
            triggerDistance =
                viewportLength * max(0, multiplier)
        }

        guard remainingDistance <= triggerDistance else {
            scrollCallbacks.isInsideReachedEndThreshold =
                false
            return
        }

        guard
            !scrollCallbacks
                .isInsideReachedEndThreshold
        else {
            return
        }

        scrollCallbacks.isInsideReachedEndThreshold =
            true
        scheduleReachedEndDelivery()
    }

    /// 동일한 실행 차례의 요청을 하나로 합쳐 callback을 안전하게 전달합니다.
    private func scheduleReachedEndDelivery() {
        guard
            !scrollCallbacks
                .isReachedEndDeliveryScheduled
        else {
            return
        }

        scrollCallbacks.isReachedEndDeliveryScheduled =
            true
        Task { @MainActor [weak self] in
            await Task.yield()
            guard let self else {
                return
            }

            scrollCallbacks
                .isReachedEndDeliveryScheduled = false
            scrollCallbacks.reachedEnd?()
        }
    }

    /// CollectionView layout의 기본 scroll 방향을 반환합니다.
    private func scrollDirection(
        of collectionView: UICollectionView
    ) -> UICollectionView.ScrollDirection {
        if let compositionalLayout =
            collectionView.collectionViewLayout
                as? UICollectionViewCompositionalLayout
        {
            return compositionalLayout
                .configuration.scrollDirection
        }

        if let flowLayout =
            collectionView.collectionViewLayout
                as? UICollectionViewFlowLayout
        {
            return flowLayout.scrollDirection
        }

        return .vertical
    }
}
