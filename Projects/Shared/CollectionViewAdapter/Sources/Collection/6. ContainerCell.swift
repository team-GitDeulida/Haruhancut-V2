//
//  ContainerCell.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import UIKit

/// 임의의 Component Content를 담는 generic collection view cell입니다.
///
/// `CellItemModelBindable.bind(cellItemModel:)`에서 type-erased 모델을
/// concrete Component로 복원합니다. Content는 cell 수명 동안 한 번만
/// 만들고, 이후에는 `render`만 다시 호출합니다.
@MainActor
public final class ContainerCell<C: Component>:
    UICollectionViewCell,
    CellItemModelBindable,
    ComponentContextBindable,
    ComponentContainerLifecycle {
    
    private var content: C.Content?
    
    var bindingContext: ComponentContext? {
        didSet {
            oldValue?.cancel()
        }
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        bindingContext?.cancel()
        bindingContext = nil
    }
    
    func contentWillDisplay() {}

    func contentDidEndDisplay() {
        bindingContext?.cancel()
    }
    
    private func component(
        from cellItemModel: any CellItemModelType
    ) -> C? {
        if let component = cellItemModel as? C {
            return component
        }

        return (cellItemModel as? AnyComponent)?
            .component(as: C.self)
    }
    
    /// Type-erased 모델에서 Component를 복원하고 Content를 렌더링합니다.
    ///
    /// - Parameter cellItemModel: Adapter가 전달한 `AnyComponent`.
    public func bind(
         cellItemModel: any CellItemModelType
     ) {
         guard
             let component = component(from: cellItemModel),
             let context = bindingContext
         else {
             assertionFailure(
                 "ContainerCell<\(C.self)>에 다른 Component 타입이 전달됐습니다."
             )
             return
         }

         let renderedContent: C.Content
         if let content {
             renderedContent = content
         } else {
             let newContent = component.createContent()
             newContent.translatesAutoresizingMaskIntoConstraints = false
             contentView.addSubview(newContent)
             NSLayoutConstraint.activate([
                 newContent.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                 newContent.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                 newContent.topAnchor.constraint(equalTo: contentView.topAnchor),
                 newContent.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
             ])
             content = newContent
             renderedContent = newContent
         }

         component.render(
             content: renderedContent,
             context: context
         )
     }
    

}
                                            
