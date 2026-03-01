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

    private let authUsecase: AuthUsecaseProtocol
    private let groupUsecase: GroupUsecaseProtocol

    // UI 상태 단일 소스
    private let groupRelay = BehaviorRelay<HCGroup?>(value: nil)

    public var userId: String? {
        userSession.userId
    }
    
    private var groupSessionObserverID: UUID?

    // MARK: - Coordinator Trigger
    public var onLogoutTapped: (() -> Void)?
    public var onImageTapped: ((Post) -> Void)?
    public var onProfileTapped: (() -> Void)?
    public var onCameraTapped: ((CameraSource) -> Void)?
    public var onCalendarImageTapped: (([Post], Date) -> Void)?

    public struct Input {
        let viewDidLoad: Observable<Void>
        let refreshTapped: Observable<Void>

        let imageTapped: Observable<Post>
        let longPressed: Observable<Post>
        let cameraButtonTapped: Observable<Void>
        let deleteConfirmed: Observable<Post>
    }

    public struct Output {
        let group: Driver<HCGroup>
        let posts: Driver<[Post]>
        let todayPosts: Driver<[Post]>
        let didTodayUpload: Driver<Bool>
        let error: Signal<Error>

        let showLongPressedAlert: Signal<Post>
        let showCameraAlert: Signal<Void>

        let postsByDate: Driver<[String: [Post]]>
    }

    public init(groupUsecase: GroupUsecaseProtocol,
                authUsecase: AuthUsecaseProtocol) {

        self.groupUsecase = groupUsecase
        self.authUsecase = authUsecase


        // 초기 세션 값 즉시 반영 (빠른 로딩)
        if let session = groupSession.entity {
            groupRelay.accept(session)
        }

        // 세션 변경 감지 → relay 동기화
        groupSessionObserverID = groupSession.bind { [weak self] session in
            guard let session else { return }
            self?.groupRelay.accept(session.toEntity())
        }
    }
    
    deinit {
        if let id = groupSessionObserverID {
            groupSession.removeObserver(id)
        }
    }

    public func transform(input: Input) -> Output {

        // MARK: - Feed Actions
        // 롱프레스 알림창
        let showLongPressedAlert = input.longPressed
            .asSignal(onErrorSignalWith: .empty())

        // 카메라 / 앨범 선택창
        let showCameraAlert = input.cameraButtonTapped
            .asSignal(onErrorSignalWith: .empty())

        // MARK: - Delete Post
        input.deleteConfirmed
            .withUnretained(self)
            .flatMapLatest { owner, post in
                owner.groupUsecase.deletePostAndReload(post: post)
            }
            .subscribe()
            .disposed(by: disposeBag)
     
        // 새로고침 트리거
        let reloadTrigger = Observable.merge(
            input.viewDidLoad,
            input.refreshTapped
        )

        // 서버 fetch → 세션 업데이트 (relay는 세션 통해 자동 갱신)
        let result = reloadTrigger
            .withUnretained(self)
            .flatMapLatest { owner, _ in
                owner.groupUsecase
                    .loadAndFetchGroup()
                    .materialize()
            }
            .share()

        // TODO: - 추후 개선 예정
        let error = Observable.merge(
            result.compactMap { $0.error }
        )
        
        // MARK: - State Streams
        let group = groupRelay
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())

        let posts = group
            .map { group in
                let allPosts = group.postsByDate.flatMap { $0.value }
                return allPosts.sorted { $0.createdAt < $1.createdAt }
            }
            .asDriver(onErrorDriveWith: .empty())

        let todayPosts = posts
            .map { posts in
                posts
                    .filter { $0.userId == self.userSession.userId }
                    .filter { $0.isToday }
            }

        let didTodayUpload = todayPosts
            .map { !$0.isEmpty }
            .distinctUntilChanged()

        let postsByDate = group
            .map { $0.postsByDate }
        
        
        
        // MARK: - Coordinator
        // 이미지 버튼
        input.imageTapped
            .bind(onNext: { [weak self] post in
                self?.onImageTapped?(post)
            })
            .disposed(by: disposeBag)

        return Output(
            group: group,
            posts: posts,
            todayPosts: todayPosts,
            didTodayUpload: didTodayUpload,
            error: error.asSignal(onErrorSignalWith: .empty()),
            showLongPressedAlert: showLongPressedAlert,
            showCameraAlert: showCameraAlert,
            postsByDate: postsByDate
        )
    }
}

/*
 // 학습 후 사용 예정
 groupSession.nonNilObservable
         .map { $0.toEntity() }
         .bind(to: groupRelay)
         .disposed(by: disposeBag)
 */
public extension SessionContext {

    var observable: Observable<Model?> {
        Observable.create { [weak self] observer in
            guard let self else {
                observer.onCompleted()
                return Disposables.create()
            }

            // 현재 값 즉시 방출 + 이후 변경 감지
            let id = self.bind { model in
                observer.onNext(model)
            }

            return Disposables.create {
                self.removeObserver(id)
            }
        }
        .share(replay: 1, scope: .whileConnected)
    }

    var nonNilObservable: Observable<Model> {
        observable.compactMap { $0 }
    }
}
