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
    /// Creates a camera feature composed of a view controller and its view model.
    /// - Returns: A `CameraPresentable` tuple containing the `CameraViewController` and its associated `CameraViewModel`.
    public func makeCamera() -> CameraPresentable {
        let vm = CameraViewModel()
        let vc = CameraViewController(viewModel: vm)
        return (vc, vm)
    }
    
    /// Creates the image upload feature's view controller and view model.
    /// - Parameter image: The initial image to be uploaded and displayed in the upload flow.
    /// - Returns: An `UploadPresentable` tuple containing the `ImageUploadViewController` and its `ImageUploadViewModel`.
    public func makeImageUpload(image: UIImage) -> UploadPresentable {
        let vm = ImageUploadViewModel(image: image)
        let vc = ImageUploadViewController(viewModel: vm)
        return (vc, vm)
    }
}