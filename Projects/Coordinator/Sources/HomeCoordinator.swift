//
//  HomeCoordinator.swift
//  Coordinator
//
//  Created by 김동현 on 1/16/26.
//

import Domain
import HomeFeature
import HomeFeatureInterface
import UIKit
import ImageFeature
import Core

public final class HomeCoordinator: NSObject, Coordinator  {
    
    public var parentCoordinator: Coordinator?
    public var childCoordinators: [Coordinator] = []
    
    private let navigationController: UINavigationController
    
    public init(
        navigationController: UINavigationController
    ) {
        self.navigationController = navigationController
    }
    
    public func start() {
        let builder = HomeFeatureBuilder() // (vc, vm) 리턴
        var home = builder.makeHome()
        
        home.vm.onLogoutTapped = { [weak self] in
            guard let self = self else { return }
            
            // 로그인 화면으로 이동
            (self.parentCoordinator as? AppCoordinator)?
                .logoutWithRotation()
            
            // HomeCoordinator 종료
            self.parentCoordinator?.childDidFinish(self)
        }
        
        // 프로필은 홈 자식이 아니므로 코디네이터를 따로 둠(poppable)
        home.vm.onProfileTapped = { [weak self] in
            guard let self = self else { return }
            
            let profileCoordinator = ProfileCoordinator(navigationController: self.navigationController)
            profileCoordinator.parentCoordinator = self
            self.childCoordinators.append(profileCoordinator)
            profileCoordinator.start()
        }
        
        home.vm.onCameraTapped = { [weak self] source in
            guard let self = self else { return }
            
            switch source {
            case .camera:
                let cameraCoordinator = CameraCoordinator(
                    navigationController: self.navigationController
                )
                
                cameraCoordinator.parentCoordinator = self
                self.childCoordinators.append(cameraCoordinator)
                cameraCoordinator.start()
            case .album:
                self.homePresentImagePicker()
            }
        }
        
        // MARK: - Feed
        // FeedDetail은 홈의 자식으로 간주하였음(poppable)
        home.vm.onImageTapped = { [weak self] post in
            guard let self = self else { return }
            let builder = FeedDetailBuilder()
            var feedDetail = builder.makeFeed(post: post)
            
            // Comment 띄우기
            feedDetail.vm.onCommentTapped = { [weak self] in
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
                previewCoordinator.start()
            }
            
            self.navigationController.pushViewController(feedDetail.vc, animated: true)
        }
        
        // MARK: - Calendar
        home.vm.onCalendarImageTapped = { [weak self] posts, date in
            guard let self = self else { return }
            let builder = CalendarDetailBuilder()
            var calendarDetail = builder.makeCalendarDetail(posts: posts,
                                                            selectedDate: date)
            // Comment 띄우기
            calendarDetail.vm.onCommentTapped = { [weak self] post in
                guard let self = self else { return }
                
                let comment = builder.makeComment(post: post)
                comment.vc.modalPresentationStyle = .pageSheet
                calendarDetail.vc.present(comment.vc, animated: true)
            }
            
            // CalendarDetail 프리뷰
            calendarDetail.vm.onImagePreviewTapped = { [weak self] imageURL in
                guard let self = self else { return }
                
                let previewCoordinator = ImagePreviewCoordinator(
                    presentingViewController: calendarDetail.vc,
                    imageURL: imageURL)
                
                previewCoordinator.parentCoordinator = self
                previewCoordinator.start()
            }
            
            calendarDetail.vc.modalPresentationStyle = .fullScreen
            self.navigationController.present(calendarDetail.vc, animated: true)
        }
        
        // 홈은 루트 플로우 → 스택 교체
        navigationController.setViewControllers([home.vc], animated: true)
    }
}

// MARK: - Delegate
extension HomeCoordinator: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func homePresentImagePicker() {
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
            picker.dismiss(animated: true)
            return
        }
        
        picker.dismiss(animated: true) { [weak self] in
            let builder = ImageFeatureBuilder()
            var upload = builder.makeImageUpload(image: image)
            // upload.vc.modalPresentationStyle = .fullScreen
            upload.vm.onUploadCompleted = { [weak self] in
                self?.navigationController.popViewController(animated: true)
            }
            
            self?.navigationController.pushViewController(upload.vc, animated: true)
        }
    }
    
    public func imagePickerControllerDidCancel(
        _ picker: UIImagePickerController
    ) {
        picker.dismiss(animated: true)
    }
}









//extension HomeCoordinator {
//    private func bindHomeActions(home: HomePresentable) {
//        var home = home
//        home.vm.onLogoutTapped = { [weak self] in
//            // 로그인 화면으로 이동
//            (self?.parentCoordinator as? AppCoordinator)?
//                .logoutWithRotation()
//            
//            // HomeCoordinator 종료
//            self?.parentCoordinator?.childDidFinish(self)
//        }
//    }
//}


//private func bindHomeActions(home: (vc: UIViewController, vm: HomeViewModelType)) {
//    
//    home.vm.onLogoutTapped = { [weak self] in
//        self?.handleLogout()
//    }
//    
//    home.vm.onProfileTapped = { [weak self] in
//        self?.showProfile()
//    }
//    
//    home.vm.onCameraTapped = { [weak self] in
//        self?.showCamera()
//    }
//    
//    home.vm.onImageTapped = { [weak self] post in
//        self?.showFeedDetail(post: post)
//    }
//}
