//
//  ContainerSupplementaryView.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/24/26.
//

import UIKit

/// Header와 footer Component를 공통으로 담는 generic supplementary view입니다.
///
/// Header 전용 Component나 footer 전용 Component는 없습니다. Section의
/// `SupplementaryView`가 배치만 지정하고 실제 UI 계약은 item과 동일한
/// `Component` 하나를 사용합니다.
@MainActor
public final class ContainerSupplementaryView<C: Component>:
    UICollectionReusableView,
    SupplementaryComponentBindable,
    ComponentContextBindable,
    ComponentContainerLifecycle
{
    private var content: C.Content?
    private var component: C?
    private var isContentActive = false

    var bindingContext: ComponentContext? {
        didSet {
            oldValue?.cancel()
            isContentActive = false
        }
    }

    /// Type-erased Component를 복원하고 Content를 렌더링합니다.
    ///
    /// - Parameter component: Adapter가 전달한 supplementary Component.
    public func bind(
        component: AnyComponent
    ) {
        guard
            let concreteComponent =
                component.component(as: C.self),
            let context = bindingContext
        else {
            assertionFailure(
                "ContainerSupplementaryView<\(C.self)>에 다른 Component 타입이 전달됐습니다."
            )
            return
        }
        self.component = concreteComponent

        let renderedContent: C.Content
        if let content {
            renderedContent = content
        } else {
            let newContent =
                concreteComponent.createContent()
            newContent.translatesAutoresizingMaskIntoConstraints = false
            addSubview(newContent)
            NSLayoutConstraint.activate([
                newContent.leadingAnchor.constraint(
                    equalTo: leadingAnchor
                ),
                newContent.trailingAnchor.constraint(
                    equalTo: trailingAnchor
                ),
                newContent.topAnchor.constraint(
                    equalTo: topAnchor
                ),
                newContent.bottomAnchor.constraint(
                    equalTo: bottomAnchor
                ),
            ])
            content = newContent
            renderedContent = newContent
        }

        concreteComponent.render(
            content: renderedContent,
            context: context
        )
        isContentActive = true
    }

    /// 화면 표시 직전에 아직 활성화되지 않은 supplementary Content를 다시 렌더링합니다.
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

    /// 화면에서 사라진 supplementary Content의 render 수명과 연결된 작업을 정리합니다.
    func contentDidEndDisplay() {
        guard isContentActive else {
            return
        }

        bindingContext?.cancel()
        isContentActive = false
    }

    /// 재사용 전에 기존 render 수명과 Component 상태를 정리합니다.
    public override func prepareForReuse() {
        super.prepareForReuse()
        bindingContext = nil
        component = nil
    }

}
