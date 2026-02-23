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
    public var onCameraTapped: ((CameraSource) -> Void)?
    
    public struct Input {
        let viewDidLoad: Observable<Void>
        let refreshTapped: Observable<Void>
        
        // feedVC
        let imageTapped: Observable<Post>
        let longPressed: Observable<Post>
        let cameraButtonTapped: Observable<Void>
        let deleteConfirmed: Observable<Post>
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
        
        // MARK: - 그룹 세션 관찰
        let group = Observable<HCGroup>.create { observer in
            // 세션 업데이트마다 방출
            let id = self.groupSession.bind { session in
                if let session {
                    observer.onNext(session.toEntity())
                }
            }
            
            // 구독 해제시 바인딩 제거
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
        
        // 롱프레스 이벤트를 Signal로 변환
        let showLongPressedAlert = input.longPressed
            .asSignal(onErrorSignalWith: .empty())
        
        // 커메라 버튼 탭을 signal로 변환
        let showCameraAlert = input.cameraButtonTapped
            .asSignal(onErrorSignalWith: .empty())
        
        // 그룹의 모든 post를 정렬하여 하나의 배열로 변환
        let posts = group
            .map { group in
                let allPosts = group.postsByDate.flatMap { $0.value }
                return allPosts.sorted { $0.createdAt < $1.createdAt }
            }
        
        // 오늘 + 현재 유저가 작성한 포스트만 필터링
        let todayPosts = posts
            .map { posts in
                posts
                    .filter { $0.userId == self.userSession.userId }
                    .filter { $0.isToday }
            }
            .asDriver(onErrorJustReturn: [])
        
        // 오늘 업로드 했는지 여부(카메라 버튼 활성화 판단용)
        let didTodayUpload = todayPosts
            .map { !$0.isEmpty }
            .distinctUntilChanged()
        
        // 삭제처리
        let deleteResult = input.deleteConfirmed
            .withUnretained(self)
            .flatMapLatest { owner, post -> Observable<Event<Void>> in
                owner.groupUsecase.deletePost(post: post)
                    .asObservable()
                    .materialize()
            }
            .share()
        
        // 삭제 성공 시 reload 트리거를 위한 Void 스트림
        let deleteSuccessTrigger = deleteResult
            .compactMap { $0.element }
            .mapToVoid()
        
        // 최초로딩 / 재로딩 / 새로고침 / 삭제 성공 후 리로드
        let loadTrigger = Observable.merge(
            input.viewDidLoad,
            input.refreshTapped,
            deleteSuccessTrigger
        )
        
        // result: Observable<Event<HCGroup>>
        // 그룹 데이터를 캐시 + 서버 순으로 가져온다
        let result = loadTrigger
            .withUnretained(self)
            .flatMapLatest { owner, _ in
                owner.groupUsecase.loadAndFetchGroup()
                    .materialize() // 에러 발생 시 스트림 이 끊기지 않도록 해준다
            }
            .share() /// 아래서 group, error가 모두 result를 구독하는데 요청 1번만 하도록 하기 위함
        
         // load 실패, delete 실패를 하나의 error 스트림으로 병합
        let error = Observable.merge(
            result.compactMap { $0.error },
            deleteResult.compactMap { $0.error }
        )
        
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
