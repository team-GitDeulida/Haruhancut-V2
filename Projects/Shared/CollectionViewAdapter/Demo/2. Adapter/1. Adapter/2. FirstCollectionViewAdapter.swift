//
//  AccountCollectionViewAdapter.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/21/26.
//

import UIKit

/// 여러 종류의 컬렉션 뷰 셀을 등록하고 구성하는 어댑터입니다.
///
/// `CellItemModelType`을 채택한 아이템을 전달받아 다음 작업을 처리합니다.
///
/// - 아이템에 필요한 셀 등록
/// - 컬렉션 뷰 데이터 제공
/// - 셀과 아이템 모델 바인딩
/// - 아이템 선택 이벤트 전달
/// - 아이템별 셀 크기 계산
final class FirstCollectionViewAdapter: NSObject {

    /// 어댑터가 관리하는 컬렉션 뷰입니다.
    ///
    /// 컬렉션 뷰가 어댑터에 의해 강하게 참조되는 것을 방지하기 위해
    /// 약한 참조로 보관합니다.
    private weak var collectionView: UICollectionView?

    /// 컬렉션 뷰에 표시할 아이템 모델입니다.
    private var items: [any CellItemModelType] = []

    /// 이미 등록한 셀의 재사용 식별자를 저장합니다.
    ///
    /// 동일한 셀 타입이 중복으로 등록되는 것을 방지합니다.
    private var registeredIdentifiers: Set<String> = []

    /// 지정한 컬렉션 뷰를 관리하는 어댑터를 생성합니다.
    ///
    /// 생성 시 컬렉션 뷰의 `dataSource`와 `delegate`를
    /// 현재 어댑터로 설정합니다.
    ///
    /// - Parameter collectionView: 어댑터가 관리할 컬렉션 뷰입니다.
    init(
        collectionView: UICollectionView
    ) {
        self.collectionView = collectionView

        super.init()

        collectionView.dataSource = self
        collectionView.delegate = self
    }

    /// 컬렉션 뷰에 표시할 아이템을 설정합니다.
    ///
    /// 전달받은 아이템에 필요한 셀을 등록한 뒤
    /// 컬렉션 뷰의 데이터를 다시 불러옵니다.
    ///
    /// - Parameter items: 컬렉션 뷰에 표시할 아이템 모델 배열입니다.
    func setItems(
        _ items: [any CellItemModelType]
    ) {
        self.items = items

        registerCellsIfNeeded(items)
        collectionView?.reloadData()
    }

    /// 아이템에서 사용하는 셀 타입을 컬렉션 뷰에 등록합니다.
    ///
    /// `registeredIdentifiers`를 사용하여 이미 등록한 셀 타입은
    /// 다시 등록하지 않습니다.
    ///
    /// - Parameter items: 셀 등록 여부를 확인할 아이템 모델 배열입니다.
    private func registerCellsIfNeeded(
        _ items: [any CellItemModelType]
    ) {
        guard let collectionView else {
            return
        }

        for item in items {
            let identifier = reuseIdentifier(
                for: item.cellType
            )

            let result = registeredIdentifiers.insert(
                identifier
            )

            guard result.inserted else {
                continue
            }

            collectionView.register(
                item.cellType,
                forCellWithReuseIdentifier: identifier
            )
        }
    }

    /// 셀 타입을 기반으로 재사용 식별자를 생성합니다.
    ///
    /// 모듈 이름을 포함한 타입 이름을 사용하여
    /// 서로 다른 모듈에 같은 이름의 셀이 있어도 충돌하지 않도록 합니다.
    ///
    /// - Parameter cellType: 재사용 식별자를 생성할 셀 타입입니다.
    /// - Returns: 셀 타입을 나타내는 문자열 식별자입니다.
    private func reuseIdentifier(
        for cellType: UICollectionViewCell.Type
    ) -> String {
        String(reflecting: cellType)
    }
}

// MARK: - UICollectionViewDataSource
/// 컬렉션 뷰에 표시할 아이템 개수와 셀 생성을 담당합니다.
extension FirstCollectionViewAdapter:
    UICollectionViewDataSource {

    /// 지정한 섹션에 표시할 아이템 개수를 반환합니다.
    ///
    /// - Parameters:
    ///   - collectionView: 아이템 개수를 요청한 컬렉션 뷰입니다.
    ///   - section: 아이템 개수를 확인할 섹션의 인덱스입니다.
    /// - Returns: 현재 설정된 아이템 모델의 개수입니다.
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        items.count
    }

    /// 지정한 위치에 표시할 셀을 생성하고 아이템 모델을 바인딩합니다.
    ///
    /// 아이템 모델의 `cellType`을 이용해 재사용 셀을 가져온 뒤,
    /// 셀이 `CellItemModelBindable`을 채택했다면 아이템 모델을 전달합니다.
    ///
    /// - Parameters:
    ///   - collectionView: 셀을 요청한 컬렉션 뷰입니다.
    ///   - indexPath: 생성할 셀의 섹션과 아이템 위치입니다.
    /// - Returns: 아이템 모델이 바인딩된 컬렉션 뷰 셀입니다.
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let itemModel = items[indexPath.item]

        let identifier = reuseIdentifier(
            for: itemModel.cellType
        )

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: identifier,
            for: indexPath
        )

        guard let bindableCell =
                cell as? any CellItemModelBindable
        else {
            assertionFailure(
                "\(itemModel.cellType)은 CellItemModelBindable을 구현해야 합니다."
            )
            return cell
        }

        bindableCell.bind(
            itemModel: itemModel
        )

        return cell
    }
}

// MARK: - UICollectionViewDelegate
/// 컬렉션 뷰 아이템의 선택 이벤트를 처리합니다.
extension FirstCollectionViewAdapter:
    UICollectionViewDelegate {

    /// 사용자가 특정 아이템을 선택했을 때 호출됩니다.
    ///
    /// 선택된 아이템 모델이 `LegacyTouchable`을 채택했다면
    /// 해당 모델의 `didTouch()`를 실행합니다.
    ///
    /// - Parameters:
    ///   - collectionView: 아이템이 선택된 컬렉션 뷰입니다.
    ///   - indexPath: 선택된 아이템의 섹션과 위치입니다.
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        let itemModel = items[indexPath.item]

        guard let touchableItem =
                itemModel as? any LegacyTouchable
        else {
            return
        }

        touchableItem.didTouch()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
/// 컬렉션 뷰에 표시되는 아이템의 크기를 계산합니다.
extension FirstCollectionViewAdapter:
    UICollectionViewDelegateFlowLayout {

    /// 지정한 위치에 표시할 셀의 크기를 반환합니다.
    ///
    /// 컬렉션 뷰의 전체 너비에서 섹션 좌우 여백을 제외한 값을
    /// 컨테이너 너비로 계산하고, 아이템 모델에 크기 계산을 요청합니다.
    ///
    /// - Parameters:
    ///   - collectionView: 셀을 표시할 컬렉션 뷰입니다.
    ///   - collectionViewLayout: 컬렉션 뷰에 적용된 레이아웃입니다.
    ///   - indexPath: 크기를 계산할 아이템의 섹션과 위치입니다.
    /// - Returns: 아이템 모델이 계산한 셀 크기입니다.
    ///   레이아웃이 `UICollectionViewFlowLayout`이 아니면 `.zero`를 반환합니다.
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let itemModel = items[indexPath.item]

        guard let layout =
                collectionViewLayout as? UICollectionViewFlowLayout
        else {
            return .zero
        }

        let horizontalInset =
            layout.sectionInset.left
            + layout.sectionInset.right

        let containerWidth =
            collectionView.bounds.width
            - horizontalInset

        return itemModel.size(
            containerWidth: containerWidth
        )
    }
}
