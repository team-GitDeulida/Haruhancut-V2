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
import UIKit

// MARK: - HomeViewModel: 세션 기반 입니다
// MARK: - ProfileViewModel: 트리거 기반 입니다
final class ProfileViewModel: ProfileViewModelType {

    let disposeBag = DisposeBag()
    private let vmReloadTrigger = PublishRelay<Void>()
    
    // MARK: - Usecase
    private let userSession: UserSession
    private let authUsecase: AuthUsecaseProtocol
    private let groupUsecase: GroupUsecaseProtocol
    
    // MARK: - Coordinator Trigger
    var onProfileImageTapped: ((String) -> Void)?
    var onProfileImageEditButtonTapped: ((@escaping (UIImage) -> Void) -> Void)?
    var onNicknameEditButtonTapped: (() -> Void)?
    var onSettingButtonTapped: (() -> Void)?
    var onImageTapped: ((Post) -> Void)?
    
    struct Input {
        let onProfileImageTapped: Observable<Void>
        let onProfileImageEditButtonTapped: Observable<Void>
        let onNicknameEditButtonTapped: Observable<Void>
        let onSettingButtonTapped: Observable<Void>
        let onImageTapped: Observable<Post>
        let reload: Observable<Void>
        let vcReloadTrigger: Observable<Void> // viewWillAppear
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
        let reloadUser = Observable.merge(
            input.vcReloadTrigger,
            vmReloadTrigger.asObservable())
            .withUnretained(self)
            .flatMapLatest { owner, _ in
                owner.authUsecase
                    .loadAndFetchUser()
                    .catch { _ in .empty() }
            }
            .share(replay: 1) // output에서 여러 곳에서 쓰면 중복 호출 방지
        
        // 그룹
        let initialGroup = groupUsecase
            .loadAndFetchGroup()
        
        let reloadGroup = input.reload
            .withUnretained(self)
            .flatMapLatest { owner, _-> Observable<HCGroup> in
                return owner.groupUsecase
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
        input.onProfileImageTapped
            .withLatestFrom(reloadUser)
            .compactMap { $0.profileImageURL }
            .bind(with: self, onNext: { owner, imageURL in
                owner.onProfileImageTapped?(imageURL)
            })
            .disposed(by: disposeBag)
        
        input.onProfileImageEditButtonTapped
            .bind(with: self, onNext: { owner, _ in
                owner.onProfileImageEditButtonTapped? { image in
                    owner.authUsecase
                        .updateProfileImageAndReloadSession(image: image)
                        .subscribe(onSuccess: { _ in
                            owner.vmReloadTrigger.accept(())
                        })
                        .disposed(by: owner.disposeBag)
                }
            })
            .disposed(by: disposeBag)
        
        input.onNicknameEditButtonTapped
            .bind(with: self, onNext: { owner, post in
                owner.onNicknameEditButtonTapped?()
            })
            .disposed(by: disposeBag)
        
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
        
        return Output(user: reloadUser.asDriver(onErrorDriveWith: .empty()),
                      myPosts: myPosts)
    }
}
