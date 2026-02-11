//
//  HomeCoordinator.swift
//  Coordinator
//
//  Created by 김동현 on 1/16/26.
//

import Domain
import HomeFeature
import UIKit

public final class HomeCoordinator: Coordinator {
    
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
            
            // 1. Profile flow 시작
            // (self.parentCoordinator as? AppCoordinator)?
            //     .startProfileFlowCoordinator()
            
            // 2. HomeCoordinator 종료 X
            // self.parentCoordinator?.childDidFinish(self)
        }
        
        // FeedDetail은 홈의 자식으로 간주하였음(poppable)
        home.vm.onImageTapped = { [weak self] post in
            guard let self = self else { return }
            let builder = FeedDetailBuilder()
            var feedDetail = builder.makeFeed(post: post)
            
            // FeedComment 띄우기
            feedDetail.vm.onCommentTapped = { [weak self] in
                guard let self = self else { return }
                guard let vm = feedDetail.vm as? FeedDetailViewModel else { return }
                
                let commentVc = builder.makeComment(vm: vm)
                commentVc.modalPresentationStyle = .pageSheet
                self.navigationController.present(commentVc, animated: true)
            }
            self.navigationController.pushViewController(feedDetail.vc, animated: true)
        }
        // 홈은 루트 플로우 → 스택 교체
        navigationController.setViewControllers([home.vc], animated: true)
    }
}
