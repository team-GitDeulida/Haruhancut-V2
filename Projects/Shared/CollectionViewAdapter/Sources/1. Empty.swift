//
//  1. Empty.swift
//  CollectionViewAdapter
//

//import UIKit
//
//struct ComponentContext {
//    let indexPath: IndexPath
//}
//
//protocol Component {
//    associatedtype Content: UIView
//    
//    func createContent() -> Content
//    func render(context: ComponentContext, content: Content)
//    func size(in collectionView: UICollectionView) -> CGSize
//}
//
//final class ContainerCell<C: Component>: UICollectionViewCell {
//    private var hostedContent: C.Content?
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//    }
//    
//    @available(*, unavailable)
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    func render(
//        component: C,
//        context: ComponentContext
//    ) {
//        let content: C.Content
//        
//        if let hostedContent {
//            content = hostedContent
//        } else {
//            let newContent = component.createContent()
//            newContent.translatesAutoresizingMaskIntoConstraints = false
//            contentView.addSubview(newContent)
//            
//            NSLayoutConstraint.activate([
//                newContent.topAnchor.constraint(equalTo: contentView.topAnchor),
//                newContent.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//                newContent.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//                newContent.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
//            ])
//            
//            hostedContent = newContent
//            content = newContent
//        }
//        component.render(context: context, content: content)
//    }
//}
//
