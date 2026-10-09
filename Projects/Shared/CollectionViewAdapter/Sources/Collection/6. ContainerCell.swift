//
//  ContainerCell.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import UIKit

/// 임의의 Component Content를 담는 generic collection view cell입니다.
///
/// `CellComponentBindable.bind(component:)`에서 type-erased Component를
/// concrete Component로 복원합니다. Content는 cell 수명 동안 한 번만
/// 만들고, 이후에는 `render`만 다시 호출합니다.
@MainActor
public final class ContainerCell<C: Component>:
    UICollectionViewCell,
    CellComponentBindable,
    ComponentContextBindable,
    ComponentContainerLifecycle {
    
    private var content: C.Content?
    private var component: C?
    private var isContentActive = false
    
    var bindingContext: ComponentContext? {
        didSet {
            oldValue?.cancel()
            isContentActive = false
        }
    }
    
    /// 재사용 전에 기존 render 수명과 Component 상태를 정리합니다.
    public override func prepareForReuse() {
        super.prepareForReuse()
        bindingContext = nil
        component = nil
    }

    /// Self-sizing 결과 높이를 pt 단위로 올림합니다.
    ///
    /// 크기 측정은 UIKit 기본 구현(`super`)에 맡깁니다. Compositional
    /// Layout의 self-sizing은 이미 제안한 너비를 고정하고 높이를 최소로
    /// 측정하므로, Content를 다시 측정해도 결과가 같고 비용만 두 배가
    /// 됩니다. 높이가 고정된 layout에서는 UIKit이 측정을 건너뜁니다.
    ///
    /// - Parameter layoutAttributes: Collection View가 제안한 Cell의 원래 layout 속성.
    /// - Returns: 측정한 높이를 올림한 layout 속성.
    public override func preferredLayoutAttributesFitting(
        _ layoutAttributes:
            UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes {
        let attributes =
            super.preferredLayoutAttributesFitting(
                layoutAttributes
            )
        attributes.size.height =
            ceil(attributes.size.height)
        return attributes
    }
    
    /// 화면 표시 직전에 아직 활성화되지 않은 Content를 다시 렌더링합니다.
    func contentWillDisplay() {
        guard
            !isContentActive,
            let component,
            let content,
            let context = bindingContext
        else {
            return
        }

        component.render(
            content: content,
            context: context
        )
        isContentActive = true
    }

    /// 화면에서 사라진 Content의 render 수명과 연결된 작업을 정리합니다.
    func contentDidEndDisplay() {
        guard isContentActive else {
            return
        }

        bindingContext?.cancel()
        isContentActive = false
    }
    
    /// Type-erased 모델에서 Component를 복원하고 Content를 렌더링합니다.
    ///
    /// - Parameter component: Adapter가 전달한 `AnyComponent`.
    func bind(
        component: AnyComponent
    ) {
        guard
            let component = component.component(as: C.self),
            let context = bindingContext
        else {
            assertionFailure(
                "ContainerCell<\(C.self)>에 다른 Component 타입이 전달됐습니다."
            )
            return
        }
        self.component = component

        let renderedContent: C.Content
        if let content {
            renderedContent = content
        } else {
            let newContent = component.createContent()
            newContent.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(newContent)
            NSLayoutConstraint.activate([
                newContent.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor
                ),
                newContent.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor
                ),
                newContent.topAnchor.constraint(
                    equalTo: contentView.topAnchor
                ),
                newContent.bottomAnchor.constraint(
                    equalTo: contentView.bottomAnchor
                ),
            ])
            content = newContent
            renderedContent = newContent
        }

        component.render(
            content: renderedContent,
            context: context
        )
        isContentActive = true
    }
    

}
                                            
