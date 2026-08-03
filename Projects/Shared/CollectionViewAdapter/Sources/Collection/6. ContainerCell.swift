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

    /// Content가 요구하는 실제 높이로 estimated layout 값을 보정합니다.
    ///
    /// Grid가 제안한 열 너비는 그대로 유지하고 세로 크기만 Auto Layout으로
    /// 계산합니다. 따라서 추정 높이가 실제 Content보다 클 때 label 영역이
    /// 불필요하게 늘어나는 현상을 방지합니다.
    ///
    /// - Parameter layoutAttributes: Collection View가 제안한 Cell의 원래 layout 속성.
    /// - Returns: 실제 Content 높이가 반영된 layout 속성.
    public override func preferredLayoutAttributesFitting(
        _ layoutAttributes:
            UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes {
        let attributes =
            super.preferredLayoutAttributesFitting(
                layoutAttributes
            )
        guard
            let content,
            attributes.size.width > 0
        else {
            return attributes
        }

        let fittingSize = CGSize(
            width: attributes.size.width,
            height:
                UIView.layoutFittingCompressedSize
                    .height
        )
        let fittedSize =
            content.systemLayoutSizeFitting(
                fittingSize,
                withHorizontalFittingPriority:
                    .required,
                verticalFittingPriority:
                    .fittingSizeLevel
            )
        guard fittedSize.height > 0 else {
            return attributes
        }

        attributes.size.height =
            ceil(fittedSize.height)
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
                                            
