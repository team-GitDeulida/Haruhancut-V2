//
//  ImagePrefiewCoordinator.swift
//  Coordinator
//
//  Created by 김동현 on 2/13/26.
//

import UIKit
import DSKit

public final class ImagePreviewCoordinator: Coordinator {
    public var parentCoordinator: Coordinator?
    public var childCoordinators: [Coordinator] = []
    
    private weak var presentingViewController: UIViewController?
    private let imageURL: String
    
    public init(
        presentingViewController: UIViewController,
        imageURL: String
    ) {
        self.presentingViewController = presentingViewController
        self.imageURL = imageURL
    }
    
    public func start() {
        let previewVC = ImagePreViewController(imageURL: imageURL)
        previewVC.modalPresentationStyle = .fullScreen
        presentingViewController?.present(previewVC, animated: true)
    }
}
