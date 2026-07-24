////
////  AnyCollectionComponent.swift
////  CollectionViewAdapter
////
////  Created by 김동현 on 7/22/26.
////
//
//import UIKit
//
///// 서로 다른 CollectionComponent 타입을
///// 동일한 배열에 저장하기 위한 내부 타입 소거 인터페이스입니다.
/////
///// 다음 Component들은 서로 다른 구체 타입이므로
///// 일반 배열에 함께 저장할 수 없습니다.
/////
///// ```swift
///// DailyPhotoCardComponent
///// NoticeComponent
///// EmptyComponent
///// ```
/////
///// 각 Component의 Cell 등록 및 Cell 생성 방법을 공통 인터페이스로 감싸
///// Adapter가 구체적인 Component 타입을 몰라도 처리할 수 있게 합니다.
//@MainActor
//private protocol AnyCollectionComponentBox: AnyObject {
//    
//    /// Component에 대응하는 Container Cell의 재사용 식별자입니다.
//    var reuseIdentifier: String { get }
//    
//    /// Component에 대응하는 Container Cell을 등록합니다.
//    ///
//    /// - Parameter collectionView: Cell을 등록할 CollectionView
//    func register(
//        in collectionView: UICollectionView
//    )
//    
//    /// Component를 렌더링한 Cell을 생성합니다.
//    ///
//    /// - Parameters:
//    ///   - collectionView: Cell을 생성할 CollectionView
//    ///   - indexPath: Cell이 표시될 위치
//    /// - Returns: Component가 렌더링된 CollectionViewCell
//    func dequeue(
//        from collectionView: UICollectionView,
//        at indexPath: IndexPath
//    ) -> UICollectionViewCell
//}
//
///// 구체적인 CollectionComponent를 보관하는 타입 소거 Box입니다.
/////
///// 실제 Component 타입을 알고 있기 때문에
///// 해당 타입에 맞는 `ComponentContainerCell<Component>`를
///// 등록하고 생성할 수 있습니다.
//@MainActor
//private final class CollectionComponentBox<Component: CollectionComponent>: AnyCollectionComponentBox {
//    
//    /// Component 타입에 대응하는 Container Cell의 재사용 식별자입니다.
//    ///
//    /// `String(reflecting:)`을 사용해 모듈명을 포함한 타입 이름을 생성합니다.
//    /// 서로 다른 모듈에서 같은 타입 이름을 사용하더라도
//    /// 재사용 식별자가 충돌할 가능성을 줄일 수 있습니다.
//    let reuseIdentifier = String(
//        reflecting: ComponentContainerCell<Component>.self
//    )
//    
//    /// Box가 보관하는 실제 Component입니다.
//    private let component: Component
//    
//    /// 구체적인 Component를 보관하는 Box를 생성합니다.
//    ///
//    /// - Parameter component: 타입을 소거할 Component
//    init(
//        component: Component
//    ) {
//        self.component = component
//    }
//    
//    func register(
//        in collectionView: UICollectionView
//    ) {
//        collectionView.register(
//            ComponentContainerCell<Component>.self,
//            forCellWithReuseIdentifier: reuseIdentifier
//        )
//    }
//    
//    func dequeue(
//        from collectionView: UICollectionView,
//        at indexPath: IndexPath
//    ) -> UICollectionViewCell {
//        guard let cell = collectionView.dequeueReusableCell(
//            withReuseIdentifier: reuseIdentifier,
//            for: indexPath
//        ) as? ComponentContainerCell<Component> else {
//            preconditionFailure(
//                """
//                ComponentContainerCell<\(Component.self)>을 \
//                생성할 수 없습니다.
//                """
//            )
//        }
//        
//        let context = CollectionComponentContext(
//            collectionView: collectionView,
//            indexPath: indexPath
//        )
//        
//        cell.render(component: component, context: context)
//        
//        return cell
//    }
//}
//
///// 서로 다른 CollectionComponent 타입을
///// 동일한 배열에 저장할 수 있도록 타입을 소거합니다.
/////
///// Adapter는 Component의 구체적인 Content View 타입을 알지 못하고,
///// `AnyCollectionComponent`가 제공하는 기능만 사용합니다.
/////
///// - Container Cell 등록
///// - Container Cell 생성
///// - Component 렌더링
/////
///// ```swift
///// let components: [AnyCollectionComponent] = [
/////     AnyCollectionComponent(
/////         DailyPhotoCardComponent(photo: photo)
/////     ),
/////     AnyCollectionComponent(
/////         NoticeComponent(message: "안내 문구")
/////     )
///// ]
///// ```
//@MainActor
//public struct AnyCollectionComponent {
//    
//    /// 타입이 소거된 Component Box
//    private let box: any AnyCollectionComponentBox
//    
//    /// 구체적인 Component의 타입을 소거합니다.
//    ///
//    /// - Parameter component: 배열에 저장할 Component
//    public init<Component: CollectionComponent>(
//        _ component: Component
//    ) {
//        box = CollectionComponentBox(
//            component: component
//        )
//    }
//    
//    /// Component에 대응하는 Container Cell의 재사용 식별자입니다.
//    ///
//    /// Adapter가 같은 Cell을 중복 등록하지 않도록 사용합니다.
//    var reuseIdentifier: String {
//        box.reuseIdentifier
//    }
//    
//    /// Component에 대응하는 Container Cell을 등록합니다.
//    ///
//    /// - Parameter collectionView: Cell을 등록할 CollectionView
//    func register(
//        in collectionView: UICollectionView
//    ) {
//        box.register(in: collectionView)
//    }
//    
//    /// Component를 렌더링한 CollectionViewCell을 생성합니다.
//    ///
//    /// - Parameters:
//    ///   - collectionView: Cell을 생성할 CollectionView
//    ///   - indexPath: Cell이 표시되는 위치
//    /// - Returns: Component가 렌더링된 Cell
//    func dequeue(
//        from collectionView: UICollectionView,
//        at indexPath: IndexPath
//    ) -> UICollectionViewCell {
//        box.dequeue(
//            from: collectionView,
//            at: indexPath
//        )
//    }
//}
//
