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

public final class ProfileCoordinator: Coordinator {
    
    public var parentCoordinator: Coordinator?
    public var childCoordinators: [Coordinator] = []
    
    private let navigationController: UINavigationController
    
    public init(
        navigationController: UINavigationController
    ) {
        self.navigationController = navigationController
    }
    
    public func start() {
        let builder = ProfileFeatureBuilder()
        var profile = builder.makeProfile()
        
        // pop 처리
        profile.vc.onPop = { [weak self] in
            guard let self else { return }
            self.parentCoordinator?.childDidFinish(self)
        }
        
        // 게시글 터치
        profile.vm.onImageTapped = { [weak self] post in
            guard let self = self else { return }
            let builder = FeedDetailBuilder()
            var feedDetail = builder.makeFeed(post: post)
            self.navigationController.pushViewController(feedDetail.vc, animated: true)
            
            // 댓글
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
                self.childCoordinators.append(previewCoordinator)
                previewCoordinator.start()
            }
        }
        
        
        // 설정 버튼
        profile.vm.onSettingButtonTapped = { [weak self] in
            print("설정 트리거")
        }
        
        // 모든 세팅 끝난 후 push
        self.navigationController.pushViewController(profile.vc, animated: true)
    }
}
