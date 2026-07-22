//
//  CollectionComponent.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/22/26.
//

import UIKit

/// CollectionView의 Cell Component가 렌더링될 때 필요한 정보를 전달합니다.
///
/// Component는 Context를 통해 다음 정보를 확인할 수 있습니다.
///
/// - Component가 표시되는 CollectionView
/// - Component가 표시되는 IndexPath
///
/// Compositional Layout에서는 Cell의 크기를 Component가 직접 계산하지 않습니다.
/// Cell의 크기와 배치는 `CollectionSectionLayout`이 담당합니다.
@MainActor
public struct CollectionComponentContext {
    
    /// Component가 표시되는 CollectionView입니다.
    public let collectionView: UICollectionView
    
    /// Component가 표시되는 위치입니다.
    public let indexPath: IndexPath
    
    /// Component Context를 생성합니다.
    ///
    /// 일반적으로 외부에서 직접 생성하지 않고
    /// `CollectionViewAdapter`가 Cell 렌더링 과정에서 생성합니다.
    ///
    /// - Parameters:
    ///   - collectionView: Component가 표시되는 CollectionView
    ///   - indexPath: Component가 표시되는 위치
    public init(
        collectionView: UICollectionView,
        indexPath: IndexPath
    ) {
        self.collectionView = collectionView
        self.indexPath = indexPath
    }
}

/// `UICollectionViewCell`을 직접 만들지 않고
/// 화면에 표시할 UIView와 렌더링 방법을 정의합니다.
///
/// Component는 다음 두 가지 책임만 가집니다.
///
/// 1. Content View 생성
/// 2. 현재 데이터를 Content View에 반영
///
/// 실제 UICollectionViewCell 생성과 재사용은
/// `ComponentContainerCell`이 담당합니다.
///
/// Cell의 크기와 배치는 `CollectionSectionLayout`이 담당합니다.
///
/// ```swift
/// struct PhotoComponent: CollectionComponent {
///     let photo: Photo
///
///     func makeContent() -> PhotoView {
///         PhotoView()
///     }
///
///     func render(
///         content: PhotoView,
///         context: CollectionComponentContext
///     ) {
///         content.render(photo)
///     }
/// }
/// ```
@MainActor
public protocol CollectionComponent {
    
    /// Component가 화면에 표시할 실제 View 타입입니다.
    ///
    /// UICollectionViewCell이 아닌 일반 UIView를 사용합니다.
    associatedtype Content: UIView
    
    /// Component가 사용할 Content View를 생성합니다.
    ///
    /// 셀에 Content View가 아직 설치되지 않은 경우에만 호출됩니다.
    /// 셀이 재사용될 때마다 새로운 View를 생성하지 않습니다.
    ///
    /// - Returns: Component가 화면에 표시할 Content View
    func makeContent() -> Content
    
    /// 현재 Component의 데이터를 Content View에 반영합니다.
    ///
    /// 셀이 처음 표시될 때뿐만 아니라 재사용될 때도 호출됩니다.
    /// 따라서 화면에 표시되는 모든 값은 이 메서드에서 설정해야 합니다.
    ///
    /// - Parameters:
    ///   - content: Component가 생성한 Content View
    ///   - context: 현재 CollectionView와 IndexPath 정보
    func render(
        content: Content,
        context: CollectionComponentContext
    )
}

/// 재사용되기 전에 초기화 작업이 필요한 Content View가 채택합니다.
///
/// `ComponentContainerCell.prepareForReuse()`가 호출되면
/// Content View가 이 프로토콜을 채택했는지 확인한 뒤
/// `prepareForReuse()`를 호출합니다.
///
/// 다음과 같은 작업에 사용할 수 있습니다.
///
/// - 이전 이미지 제거
/// - 이미지 요청 취소
/// - Label 텍스트 초기화
/// - 탭 이벤트 클로저 제거
/// - 로딩 상태 초기화
@MainActor
public protocol CollectionReusableContent: AnyObject {
    
    /// Content View가 재사용되기 직전에 호출됩니다.
    ///
    /// 이전 Component의 상태가 새로운 Component에 남지 않도록
    /// 필요한 값을 초기화합니다.
    func prepareForReuse()
}
