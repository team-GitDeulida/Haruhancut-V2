//
//  CameraViewModel.swift
//  ImageFeature
//
//  Created by 김동현 on 2/20/26.
//

import RxSwift
import ImageFeatureInterface
import UIKit

final class CameraViewModel: CameraViewModelType {
    
    // MARK: - Coordinator
    var onCameraButtonTapped: ((UIImage) -> Void)?
    
    private let disposeBag = DisposeBag()
    
    struct Input {
        let cameraButtonTapped: Observable<UIImage>
    }
    struct Output {}
    
    /// Subscribes to the camera button image stream and forwards each captured image to the coordinator callback.
    /// 
    /// Binds `input.cameraButtonTapped` to `onCameraButtonTapped` and retains the subscription in `disposeBag`.
    /// - Parameters:
    ///   - input: An `Input` containing `cameraButtonTapped`, an observable that emits captured `UIImage` instances.
    /// - Returns: An `Output` value representing the view model's outputs (empty).
    func transform(input: Input) -> Output {
        input.cameraButtonTapped
            .bind(with: self, onNext: { owner, image in
                self.onCameraButtonTapped?(image)
            }).disposed(by: disposeBag)
        return Output()
    }
}