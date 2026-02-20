//  ImageUploadViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 6/18/25.
//

import UIKit
import RxSwift
import RxCocoa
import ImageFeatureInterface

final class ImageUploadViewController: UploadViewControllerType {
    var onPop: (() -> Void)?
    
    private let customView: ImageUploadView
    private let disposeBag = DisposeBag()
    private let viewModel: ImageUploadViewModel
    
    // MARK: - Initializer
    init(viewModel: ImageUploadViewModel) {
        self.viewModel = viewModel
        self.customView = ImageUploadView(image: viewModel.image)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Sets the view controller's root view to the controller's ImageUploadView.
    override func loadView() {
        self.view = customView
    }

    /// Performs additional setup after the view has been loaded.
    /// 
    /// Establishes bindings between the view and its view model by calling `bindViewModel()`.
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }
    
    /// Registers the upload button's `.touchUpInside` event to invoke `uploadAndBackToHome` on this view controller.
    private func addTarget() {
        
        customView.uploadButton.addTarget(self,
                                          action: #selector(uploadAndBackToHome),
                                          for: .touchUpInside)
    }

    /// Binds the view model's inputs and outputs to the view's UI elements.
    /// 
    /// Creates an input using the upload button's tap events, transforms it through the view model,
    /// and subscribes to the `isUploading` output to disable/enable the upload button and adjust the view's alpha while an upload is in progress.
    private func bindViewModel() {
        let input = ImageUploadViewModel.Input(uploadButtonTapped: customView.uploadButton.rx.tap.asObservable())
        let output = viewModel.transform(input: input)
        
        // 업로드 중 버튼 비활성화
        output.isUploading
            .map { !$0 }
            .drive(customView.uploadButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        // 업로드 중 aplha 조절
        output.isUploading
            .map { $0 ? 0.5 : 1.0 }
            .drive(customView.rx.alpha)
            .disposed(by: disposeBag)
    }
    
    /// Updates the UI to reflect the start of an upload operation.
    /// 
    /// Disables the upload button and sets the view's alpha to 0.5 to indicate a non-interactive/uploading state.
    @objc private func uploadAndBackToHome() {
        customView.uploadButton.isEnabled = false
        customView.alpha = 0.5
        

    }
}