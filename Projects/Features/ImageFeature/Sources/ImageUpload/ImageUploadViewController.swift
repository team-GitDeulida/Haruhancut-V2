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

    // MARK: - LifeCycle
    override func loadView() {
        self.view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }
    
    // MARK: - addTarget
    private func addTarget() {
        
        customView.uploadButton.addTarget(self,
                                          action: #selector(uploadAndBackToHome),
                                          for: .touchUpInside)
    }

    // MARK: - Bindings
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
    
    @objc private func uploadAndBackToHome() {
        customView.uploadButton.isEnabled = false
        customView.alpha = 0.5
        

    }
}
