//
//  ProfileCoordinatorV2.swift
//  Coordinator
//
//  Created by 김동현 on 4/22/26.
//

import Domain
import ProfileFeature
import UIKit
import HomeFeatureV2
import ImageFeature
import Core

public final class ProfileCoordinatorV2: NSObject, Coordinator {
    
    public var parentCoordinator: Coordinator?
    public var childCoordinators: [Coordinator] = []
    
    private let navigationController: UINavigationController
    private weak var profileViewController: UIViewController?
    
    public init(
        navigationController: UINavigationController
    ) {
        self.navigationController = navigationController
    }
    
    private var imagePickerCompletion: ((UIImage) -> Void)?
    
    public func start() {
        let builder = ProfileFeatureBuilder()
        var profile = builder.makeProfile()
        profileViewController = profile.vc
        navigationController.delegate = self
        
        profile.vm.onProfileImageTapped = { [weak self] imageURL in
            guard let self = self else { return }
            let previewCoordinator = ImagePreviewCoordinator(presentingViewController: self.navigationController,
                                                             imageURL: imageURL)
            previewCoordinator.parentCoordinator = self
            self.childCoordinators.append(previewCoordinator)
            previewCoordinator.start()
        }
        
        profile.vm.onProfileImageEditButtonTapped = { [weak self] completion in
            guard let self = self else { return }
            profilePresentImagePicker(completion: completion)
        }
        
        profile.vm.onImageTapped = { [weak self] post in
            guard let self = self else { return }
            let builder = HomeFeatureV2.FeedDetailBuilder()
            var feedDetail = builder.makeFeed(post: post)
            let feedDetailViewController = feedDetail.vc
            profileViewController?.navigationItem.backButtonDisplayMode = .minimal
            self.navigationController.pushViewController(feedDetail.vc, animated: true)
            
            feedDetail.vm.onCommentTapped = { [weak self] post in
                guard let self = self else { return }
                
                let commentVC = builder.makeComment(post: post, onDismiss: { [weak feedDetailViewController] in
                    feedDetailViewController?.refresh()
                })
                commentVC.modalPresentationStyle = .pageSheet
                self.navigationController.present(commentVC, animated: true)
            }
            
            feedDetail.vm.onImagePreviewTapped = { [weak self] imageURL in
                guard let self = self else { return }
                
                let previewCoordinator = ImagePreviewCoordinator(
                    presentingViewController: self.navigationController,
                    imageURL: imageURL)
                
                previewCoordinator.parentCoordinator = self
                self.childCoordinators.append(previewCoordinator)
                previewCoordinator.start()
            }
        }
        
        profile.vm.onSettingButtonTapped = { [weak self] in
            guard let self = self else { return }
            let setting = builder.makeSetting()
            
            profileViewController?.navigationItem.backButtonDisplayMode = .default
            self.navigationController.pushViewController(setting.vc, animated: true)
        }
        
        profile.vm.onNicknameEditButtonTapped = { [weak self] in
            guard let self = self else { return }
            var nicknameEdit = builder.makeNicknameEdit()
            
            nicknameEdit.vm.onPopButtonTapped = { [weak self] in
                guard let self else { return }
                self.navigationController.popViewController(animated: true)
            }
            
            profileViewController?.navigationItem.backButtonDisplayMode = .default
            self.navigationController.pushViewController(nicknameEdit.vc, animated: true)
        }
        
        self.navigationController.pushViewController(profile.vc, animated: true)
    }
}

extension ProfileCoordinatorV2: UINavigationControllerDelegate {
    public func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        guard let profileViewController,
              !navigationController.viewControllers.contains(profileViewController) else {
            return
        }

        self.profileViewController = nil
        navigationController.delegate = nil
        parentCoordinator?.childDidFinish(self)
    }
}

extension ProfileCoordinatorV2: UIImagePickerControllerDelegate {
    
    func profilePresentImagePicker(completion: @escaping (UIImage) -> Void) {
        imagePickerCompletion = completion
        
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            return
        }
        
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        picker.delegate = self
        
        if let popover = picker.popoverPresentationController {
            popover.sourceView = navigationController.view
            popover.sourceRect = CGRect(
                x: navigationController.view.bounds.midX,
                y: navigationController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }
        navigationController.present(picker, animated: true)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let image = info[.originalImage] as? UIImage else {
            self.imagePickerCompletion = nil
            picker.dismiss(animated: true)
            return
        }

        picker.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.imagePickerCompletion?(image)
            self.imagePickerCompletion = nil
        }
    }
    
    public func imagePickerControllerDidCancel(
        _ picker: UIImagePickerController
    ) {
        self.imagePickerCompletion = nil
        picker.dismiss(animated: true)
    }
}
