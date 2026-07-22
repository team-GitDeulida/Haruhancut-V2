//
//  ComponentContainerCell.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/22/26.
//

import UIKit

@MainActor
final class ComponentContainerCell<Component: CollectionComponent>: UICollectionViewCell {
    
    /// 현재 Cell 내부에 설치된 Content View입니다.
    ///
    /// Cell이 재사용되더라도 Content View를 다시 생성하지 않고
    /// 기존 인스턴스를 재사용합니다.
    private var hostedContent: Component.Content?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Content View가 CollectionReusableContent를 채택한 경우
        // 재사용 초기화 메서드를 호출합니다.
        (hostedContent as? CollectionReusableContent)?
            .prepareForReuse()
    }
    
    /// Component가 생성한 Content View를 Cell에 설치합니다.
    ///
    /// Content View가 Cell의 contentView 전체 영역을 채우도록
    /// Auto Layout 제약을 설정합니다.
    ///
    /// - Parameter content: Cell 내부에 설치할 Content View
    /// - Returns: 설치된 Content View
    @discardableResult
    private func installContent(
        _ content: Component.Content
    ) -> Component.Content {
        content.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(content)
        
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: contentView.topAnchor),
            content.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        hostedContent = content
        return content
    }
    
    /// Cell의 기본 UI 속성을 설정합니다.
    private func configureCell() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }
    
    /// Component의 Content View를 Cell에 표시합니다.
    ///
    /// Content View가 아직 없다면 `makeContent()`로 생성하고,
    /// 이미 존재한다면 기존 Content View를 그대로 재사용합니다.
    ///
    /// 이후 Component의 `render(content:context:)`를 호출해
    /// 현재 데이터를 화면에 반영합니다.
    ///
    /// - Parameters:
    ///   - component: 현재 Cell에 표시할 Component
    ///   - context: 현재 CollectionView와 IndexPath 정보
    func render(
        component: Component,
        context: CollectionComponentContext
    ) {
        let content: Component.Content
        
        if let hostedContent {
            content = hostedContent
        } else {
            content = installContent(component.makeContent())
        }
        
        component.render(content: content, context: context)
    }
}
