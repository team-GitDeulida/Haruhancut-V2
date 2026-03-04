//
//  ProfileCoordinator.swift
//  Coordinator
//
//  Created by 김동현 on 2/9/26.
//

import Domain
import ProfileFeature
import UIKit
import HomeFeature
import ImageFeature
import Core

public final class ProfileCoordinator: NSObject, Coordinator {
    
    public var parentCoordinator: Coordinator?
    public var childCoordinators: [Coordinator] = []
    
    private let navigationController: UINavigationController
    
    public init(
        navigationController: UINavigationController
    ) {
        self.navigationController = navigationController
    }
    
    private var imagePickerCompletion: ((UIImage) -> Void)?
    
    public func start() {
        let builder = ProfileFeatureBuilder()
        var profile = builder.makeProfile()
        
        // pop 처리
        profile.vc.onPop = { [weak self] in
            guard let self else { return }
            self.parentCoordinator?.childDidFinish(self)
        }
        
        // 프로필 미리보기
        profile.vm.onProfileImageTapped = { [weak self] imageURL in
            guard let self = self else { return }
            let previewCoordinator = ImagePreviewCoordinator(presentingViewController: self.navigationController,
                                                             imageURL: imageURL)
            previewCoordinator.parentCoordinator = self
            self.childCoordinators.append(previewCoordinator)
            previewCoordinator.start()
        }
        
        // 프로필 수정
        profile.vm.onProfileImageEditButtonTapped = { [weak self] completion in
            guard let self = self else { return }
            profilePresentImagePicker(completion: completion)
        }
        
        // 게시글 터치
        profile.vm.onImageTapped = { [weak self] post in
            guard let self = self else { return }
            let builder = FeedDetailBuilder()
            var feedDetail = builder.makeFeed(post: post)
            self.navigationController.pushViewController(feedDetail.vc, animated: true)
            
            // 댓글
            feedDetail.vm.onCommentTapped = { [weak self] post in
                guard let self = self else { return }
                
                let commentVC = builder.makeComment(post: post)
                commentVC.modalPresentationStyle = .pageSheet
                self.navigationController.present(commentVC, animated: true)
            }
            
            // 이미지 프리뷰
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
        
        // 설정 버튼
        profile.vm.onSettingButtonTapped = { [weak self] in
            guard let self = self else { return }
            let setting = builder.makeSetting()
            
            // 모든 설정 세팅 끝난 후 push
            self.navigationController.pushViewController(setting.vc, animated: true)
        }
        
        // 닉네임 편집 버튼
        profile.vm.onNicknameEditButtonTapped = { [weak self] in
            guard let self = self else { return }
            var nicknameEdit = builder.makeNicknameEdit()
            
            // 닉네임 편집 화면에서 성공 시 뒤로가기
            nicknameEdit.vm.onPopButtonTapped = { [weak self] in
                guard let self else { return }
                self.navigationController.popViewController(animated: true)
            }
            
            // 모든 설정 세팅 끝난 후 push
            self.navigationController.pushViewController(nicknameEdit.vc, animated: true)
        }
        
        // 모든 세팅 끝난 후 push
        self.navigationController.pushViewController(profile.vc, animated: true)
    }
}

extension ProfileCoordinator: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    func profilePresentImagePicker(completion: @escaping (UIImage) -> Void) {
        // MARK: - Picker열떄 completion 저장
        imagePickerCompletion = completion
        
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            return
        }
        
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        picker.delegate = self
        
        // iPad 대응
        // - ipad에서 UIImagePicker가 기본적으로 popOver로 뜨기 때문에 popOver 설정이 되어있지 않으면 delegate가 호출되지 않거나
        // - 빈응이 없는 것 처럼 보일 수 있다
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

        // MARK: - Delegate에서 Completion 호출
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

