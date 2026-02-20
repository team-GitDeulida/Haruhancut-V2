//
//  CameraCoordinator.swift
//  Coordinator
//
//  Created by 김동현 on 2/13/26.
//

import UIKit
import ImageFeature

public final class CameraCoordinator: Coordinator {
    
    public var parentCoordinator: Coordinator?
    public var childCoordinators: [Coordinator] = []
    
    private let navigationController: UINavigationController
    
    public init(
        navigationController: UINavigationController
    ) {
        self.navigationController = navigationController
    }
    
    /// Starts the camera coordination flow by presenting the camera view and wiring an image upload flow.
    /// 
    /// Configures the camera view model to create and push an image upload view when a photo is captured, and configures the upload view model to return to the root view controller when the upload completes.
    public func start() {
        let builder = ImageFeatureBuilder()
        var camera = builder.makeCamera()
        
        camera.vm.onCameraButtonTapped = { [weak self] image in
            guard let self = self else { return }
            var upload = builder.makeImageUpload(image: image)
            
            upload.vm.onUploadCompleted = { [weak self] in
                self?.navigationController.popToRootViewController(animated: true)
            }
            
            self.navigationController.pushViewController(upload.vc, animated: true)
        }
        navigationController.pushViewController(camera.vc, animated: true)
    }
}