//
//  CameraFeatureBuilder.swift
//  ImageFeature
//
//  Created by 김동현 on 2/20/26.
//

import ImageFeatureInterface
import UIKit

public protocol ImageFeatureBuildable {
    func makeCamera() -> CameraPresentable
    func makeImageUpload(image: UIImage) -> UploadPresentable
}

public final class ImageFeatureBuilder {
    public init() {}
}

extension ImageFeatureBuilder: ImageFeatureBuildable {
    public func makeCamera() -> CameraPresentable {
        let vm = CameraViewModel()
        let vc = CameraViewController(viewModel: vm)
        return (vc, vm)
    }
    
    public func makeImageUpload(image: UIImage) -> UploadPresentable {
        let vm = ImageUploadViewModel(image: image)
        let vc = ImageUploadViewController(viewModel: vm)
        return (vc, vm)
    }
}
