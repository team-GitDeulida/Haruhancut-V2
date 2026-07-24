//
//  CollectionViewLayoutAdapter.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import UIKit

/// Section model과 Compositional Layout section provider를 연결합니다.
///
/// KarrotListKit의 `CollectionViewLayoutAdapter`와 같은 역할입니다.
/// 사용자가 `UICollectionViewCompositionalLayout`을 직접 만들고 싶을 때
/// 이 객체의 `sectionLayout`을 section provider로 전달합니다.
///
/// 동일한 인스턴스를 `CollectionViewAdapter`에도 전달해야 bind된 최신
/// Section 정보로 layout을 생성할 수 있습니다.
@MainActor
public final class CollectionViewLayoutAdapter {
    private var sections: [ResolvedSection] = []

    /// 현재 bind된 Section에 대응하는 Compositional Layout provider입니다.
    ///
    /// - Important: 이 provider로 layout을 만든 뒤 같은
    ///   `CollectionViewLayoutAdapter`를 `CollectionViewAdapter`에
    ///   주입해야 합니다.
    public var sectionLayout:
        (
            Int,
            NSCollectionLayoutEnvironment
        ) -> NSCollectionLayoutSection?
    {
        { [weak self] sectionIndex, _ in
            guard
                let self,
                self.sections.indices.contains(sectionIndex)
            else {
                return nil
            }
            return self.sections[sectionIndex]
                .makeLayoutSection()
        }
    }

    /// 빈 layout adapter를 만듭니다.
    public init() {}

    func updateSections(
        _ sections: [ResolvedSection]
    ) {
        self.sections = sections
    }
}
