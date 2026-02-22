//
//  HomeViewModel.swift
//  HomeFeature
//
//  Created by 김동현 on 1/16/26.
//
// https://ios-development.tistory.com/872

import Foundation
import HomeFeatureInterface
import RxSwift
import RxRelay
import Domain
import RxCocoa
import Core

public final class HomeViewModel: HomeViewModelType {
    private let disposeBag = DisposeBag()
    @Dependency private var userSession: UserSession
    @Dependency private var groupSession: GroupSession
    
    // MARK: - Properties
    private let groupUsecase: GroupUsecaseProtocol
    public var userId: String? {
        userSession.userId
    }
    
    // MARK: - Coordinator Trigger
    public var onLogoutTapped: (() -> Void)?
    public var onImageTapped: ((Post) -> Void)?
    public var onProfileTapped: (() -> Void)?
    // public var onCameraTapped: (() -> Void)?
    public var onCameraTapped: ((CameraSource) -> Void)?
    
    public struct Input {
        let viewDidLoad: Observable<Void>
        let refreshTapped: Observable<Void>
        
        // feedVC
        let imageTapped: Observable<Post>
        let longPressed: Observable<Post>
        let cameraButtonTapped: Observable<Void>
    }
    
    public struct Output {
        let group: Driver<HCGroup>
        let posts: Driver<[Post]>
        let todayPosts: Driver<[Post]>
        var didTodayUpload: Driver<Bool>
        let error: Signal<Error>
        
        // feedVC
        let showLongPressedAlert: Signal<Post>
        let showCameraAlert: Signal<Void>
    }
    
    public init(groupUsecase: GroupUsecaseProtocol) {
        self.groupUsecase = groupUsecase
    }
    
    public func transform(input: Input) -> Output {
        
        // 최초로딩 / 재로딩
        let loadTrigger = Observable.merge(input.viewDidLoad,
                                           input.refreshTapped)
        
        // result: Observable<Event<HCGroup>>
        let result = loadTrigger
            .withUnretained(self)
            .flatMapLatest { owner, _ in
                owner.groupUsecase.loadAndFetchGroup()
                    .materialize() // 에러 발생 시 스트림 이 끊기지 않도록 해준다
            }
            .share() /// 아래서 group, error가 모두 result를 구독하는데 요청 1번만 하도록 하기 위함
        
        let group = Observable<HCGroup>.create { observer in
            let id = self.groupSession.bind { session in
                if let session {
                    observer.onNext(session.toEntity())
                }
            }
            
            return Disposables.create {
                self.groupSession.removeObserver(id)
            }
        }
        .share() /// Rx는 기본적으로 Cold Observable이다 구독자가 2명 이상이면 블록이 2번이상 실행됨.. 중복방지를위함
        
        
        
        
        // MARK: - Feed
        input.imageTapped
            .bind(onNext: { [weak self] post in
                self?.onImageTapped?(post)
            })
            .disposed(by: disposeBag)
        
        let showLongPressedAlert = input.longPressed
            .asSignal(onErrorSignalWith: .empty())
        
        let showCameraAlert = input.cameraButtonTapped
            .asSignal(onErrorSignalWith: .empty())
        
        let posts = group
            .map { group in
                let allPosts = group.postsByDate.flatMap { $0.value }
                return allPosts.sorted { $0.createdAt < $1.createdAt }
            }
        
        let todayPosts = posts
            .map { posts in
                posts
                    .filter { $0.userId == self.userSession.userId }
                    .filter { $0.isToday }
            }
            .asDriver(onErrorJustReturn: [])
        
        let didTodayUpload = todayPosts
            .map { !$0.isEmpty }
            .distinctUntilChanged()
        
        let error = result.compactMap { $0.error }
        return Output(group: group.asDriver(onErrorDriveWith: Driver.empty()),
                      posts: posts.asDriver(onErrorDriveWith: Driver.empty()),
                      todayPosts: todayPosts,
                      didTodayUpload: didTodayUpload,
                      error: error.asSignal(onErrorSignalWith: Signal.empty()),
                      showLongPressedAlert: showLongPressedAlert,
                      showCameraAlert: showCameraAlert)
    }
}





















// let logoutButtonTapped: Observable<Void>


// bind: 값을 UI나 Binder로 꽂을 때
// Driver는 UI용
//        input.logoutButtonTapped
//            .bind(onNext: { [weak self] in
//                self?.onLogoutTapped?()
//            })
//            .disposed(by: disposeBag)




//    func fetchGroup() {
//        groupUsecase.fetchGroup()
//            .observe(on: MainScheduler.instance)
//            .subscribe(
//                onSuccess: { [weak self] group in
//                    self?.group.accept(group)
//                    print("그룹 디버깅: \(group)")
//
//                    let allPosts = group.postsByDate.flatMap { $0.value }
//                    let sortedPosts = allPosts.sorted(by: { $0.createdAt < $1.createdAt })
//                    self?.posts.accept(sortedPosts)
//                },
//                onFailure: { error in
//                    print("❌ fetchGroup error:", error)
//                }
//            )
//            .disposed(by: disposeBag)
