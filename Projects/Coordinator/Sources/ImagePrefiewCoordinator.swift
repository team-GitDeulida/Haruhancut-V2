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
    
    private let navigationController: UINavigationController
    private let imageURL: String
    
    public init(
        navigationController: UINavigationController,
        imageURL: String
    ) {
        self.navigationController = navigationController
        self.imageURL = imageURL
    }
    
    public func start() {
        let previewVC = ImagePreViewController(imageURL: imageURL) // 어떻게하지
        previewVC.modalPresentationStyle = .fullScreen
        navigationController.present(previewVC, animated: true)
    }
}
