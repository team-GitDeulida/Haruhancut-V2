//
//  ProfileViewModel.swift
//  ProfileFeature
//
//  Created by 김동현 on 2/27/26.
//

import ProfileFeatureInterface
import Domain
import RxSwift
import RxCocoa
import Core

final class ProfileViewModel: ProfileViewModelType {

    let disposeBag = DisposeBag()
    
    // MARK: - Usecase
    private let userSession: UserSession
    private let authUsecase: AuthUsecaseProtocol
    private let groupUsecase: GroupUsecaseProtocol
    
    // MARK: - Coordinator Trigger
    var onSettingButtonTapped: (() -> Void)?
    var onImageTapped: ((Post) -> Void)?
    
    struct Input {
        let onSettingButtonTapped: Observable<Void>
        let onImageTapped: Observable<Post>
        let reload: Observable<Void>
    }
    
    struct Output {
        let user: Driver<User>
        let myPosts: Driver<[Post]>
    }
    
    init(userSession: UserSession, authUsecase: AuthUsecaseProtocol, groupUsecase: GroupUsecaseProtocol) {
        self.userSession = userSession
        self.authUsecase = authUsecase
        self.groupUsecase = groupUsecase
    }
    
    func transform(input: Input) -> Output {
        
        // 유저
        let user = authUsecase
            .loadAndFetchUser()
        
        // 그룹
        let initialGroup = groupUsecase
            .loadAndFetchGroup()
            .do(onNext: { print("group 방출됨:", $0) })
        
        let reloadGroup = input.reload
            .flatMapLatest { [weak self] _ -> Observable<HCGroup> in
                guard let self else { return .empty() }
                return self.groupUsecase
                    .loadAndFetchGroup()
                    .catch { _ in .empty() }
            }
        
        // 최초 + reload 합치기
        let group = Observable
            .merge(initialGroup, reloadGroup)
            .share(replay: 1)
        
        // 전체 포스트
        let myPosts = group
            .map { group in
                group.postsByDate
                    .flatMap { $0.value }
                    .filter { $0.userId == self.userSession.userId }
                    .sorted { $0.createdAt > $1.createdAt }
            }
            .asDriver(onErrorJustReturn: [])

        
        // MARK: - Coordinator
        input.onImageTapped
            .bind(with: self, onNext: { owner, post in
                owner.onImageTapped?(post)
            })
            .disposed(by: disposeBag)
        
        input.onSettingButtonTapped
            .bind(with: self, onNext: { owner, _ in
                owner.onSettingButtonTapped?()
            })
            .disposed(by: disposeBag)
        
        return Output(user: user.asDriver(onErrorDriveWith: .empty()),
                      myPosts: myPosts)
    }
}






