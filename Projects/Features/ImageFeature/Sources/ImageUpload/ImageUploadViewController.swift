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

    private struct NavigationState {
        let isNavigationViewInteractionEnabled: Bool
        let isPopGestureEnabled: Bool?
    }

    private let customView: ImageUploadView
    private let disposeBag = DisposeBag()
    private let viewModel: ImageUploadViewModel

    private weak var lockedNavigationController: UINavigationController?
    private var navigationState: NavigationState?
    private var loadingView: UIView?

    // MARK: - Initializer
    init(viewModel: ImageUploadViewModel) {
        self.viewModel = viewModel
        self.customView = ImageUploadView(image: viewModel.image)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        guard lockedNavigationController?.topViewController !== self else { return }
        hideLoadingIndicator()
        unlockNavigation()
    }

    private func bindViewModel() {
        let input = ImageUploadViewModel.Input(uploadButtonTapped: customView.uploadButton.rx.tap.asObservable())
        let output = viewModel.transform(input: input)

        output.isUploading
            .drive(with: self) { owner, isUploading in
                owner.updateUploadingState(isUploading)
            }
            .disposed(by: disposeBag)
    }

    private func updateUploadingState(_ isUploading: Bool) {
        customView.uploadButton.isEnabled = !isUploading

        if isUploading {
            lockNavigation()
            showLoadingIndicator()
        } else {
            hideLoadingIndicator()
            unlockNavigation()
        }
    }

    private func showLoadingIndicator() {
        guard loadingView == nil else { return }

        let rootView = navigationController?.view ?? customView
        let loadingView = UIView()
        loadingView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        loadingView.isUserInteractionEnabled = true
        loadingView.translatesAutoresizingMaskIntoConstraints = false

        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .mainWhite
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.startAnimating()

        loadingView.addSubview(indicator)
        rootView.addSubview(loadingView)
        self.loadingView = loadingView

        NSLayoutConstraint.activate([
            loadingView.topAnchor.constraint(equalTo: rootView.topAnchor),
            loadingView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
            loadingView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
            indicator.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor)
        ])
    }

    private func hideLoadingIndicator() {
        loadingView?.removeFromSuperview()
        loadingView = nil
    }

    private func lockNavigation() {
        guard navigationState == nil, let navigationController else { return }

        let popGestureRecognizer = navigationController.interactivePopGestureRecognizer
        lockedNavigationController = navigationController
        navigationState = NavigationState(
            isNavigationViewInteractionEnabled: navigationController.view.isUserInteractionEnabled,
            isPopGestureEnabled: popGestureRecognizer?.isEnabled
        )

        navigationController.view.isUserInteractionEnabled = false
        popGestureRecognizer?.isEnabled = false
    }

    private func unlockNavigation() {
        guard let navigationState, let navigationController = lockedNavigationController else { return }

        let popGestureRecognizer = navigationController.interactivePopGestureRecognizer
        navigationController.view.isUserInteractionEnabled = navigationState.isNavigationViewInteractionEnabled

        if let isPopGestureEnabled = navigationState.isPopGestureEnabled {
            popGestureRecognizer?.isEnabled = isPopGestureEnabled
        }

        self.navigationState = nil
        lockedNavigationController = nil
    }
}
