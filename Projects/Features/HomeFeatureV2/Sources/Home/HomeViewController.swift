//
//  HomeViewController.swift
//  HomeFeatureV2Interface
//
//  Created by 김동현 on 4/19/26.
//

import UIKit
import ReactorKit
import CarbonListKit
import DSKit
import RxCocoa
import Domain
import HomeFeatureV2Interface

final class HomeViewController: UIViewController {

    var disposeBag = DisposeBag()
    var currentPageRelay = BehaviorRelay<Int>(value: 0)
    weak var routeTrigger: HomeRouteTrigger?

    private let segmentedBar: CustomSegmentedBarView = {
        let segment = CustomSegmentedBarView(items: [
            LocalizationKey.homeSegmentFeed.localized,
            LocalizationKey.homeSegmentCalendar.localized
        ])
        return segment
    }()
    
    let feedVC: FeedViewController
    let calendarVC: CalendarViewController
    
    private lazy var pageViewController: UIPageViewController = {
        let vc = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        vc.delegate = self
        vc.dataSource = self
        return vc
    }()
        
    private var dataViewControllers: [UIViewController] { [feedVC, calendarVC] }
    
    // 캘린더 영역만 막고 나머지 페이지는 이동하기 위한 로직 4
    private var pageScrollView: UIScrollView? {
        pageViewController.view.subviews.first { $0 is UIScrollView } as? UIScrollView
    }
    
    init(feedReactor: FeedReactor, calendarReactor: CalendarReactor) {
        self.feedVC = FeedViewController(reactor: feedReactor)
        self.calendarVC = CalendarViewController(reactor: calendarReactor)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupPageViewController()
        bind()
        
        // 캘린더 영역만 막고 나머지 페이지는 이동하기 위한 로직 5
        calendarVC.gestureDelegate = self
    }
    
    private func setupNavigation() {
        /// 뷰 배경 색상
        view.backgroundColor = .background
        
        /// 네비게이션 버튼 색상
        self.navigationController?.navigationBar.tintColor = .mainWhite
        
        /// 네비게이션 제목
        segmentedBar.sizeToFit() // 글자 길이에 맞게 label 크기 조정
        self.navigationItem.titleView = segmentedBar
        
        /// 좌측 네비게이션 버튼
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "list.bullet"),
            style: .plain,
            target: nil,
            action: nil)
        self.navigationItem.leftBarButtonItem?.tintColor = .mainWhite
        
        /// 우측 네비게이션 버튼
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "person.fill"),
            style: .plain,
            target: nil,
            action: nil)
        self.navigationItem.rightBarButtonItem?.tintColor = .mainWhite
        
        /// 자식 화면에서 뒤로가기
        let backItem = UIBarButtonItem()
        backItem.title = LocalizationKey.homeNavigationBack.localized
        backItem.tintColor = .mainWhite
        navigationItem.backBarButtonItem = backItem
    }
    
    private func setupPageViewController() {
        addChild(pageViewController)                      // 자식 등록
        view.addSubview(pageViewController.view)          // 뷰 추가
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        pageViewController.didMove(toParent: self)
        pageViewController.setViewControllers(
            [feedVC],
            direction: .forward,
            animated: false
        )
    }
    
    func bind() {
        let currentPageDriver = currentPageRelay.asDriver()
        
        // SegmentedControl 변경 값(0, 1)을 currentPageRelay에 갱신
        segmentedBar.segmentedControl.rx.selectedSegmentIndex
            .bind(to: currentPageRelay)
            .disposed(by: disposeBag)
        
        // 스와이프 시 세그먼트 바 자동 움직임
        currentPageDriver
            .distinctUntilChanged()
            .drive(with: self) { vc, index in
                vc.segmentedBar.segmentedControl.selectedSegmentIndex = index
                vc.segmentedBar.moveUnderline(animated: true)
            }
            .disposed(by: disposeBag)

        feedVC.imageTapped
            .drive(with: self) { owner, post in
                owner.routeTrigger?.onImageTapped?(post)
            }
            .disposed(by: disposeBag)

        feedVC.longPressed
            .drive(with: self) { owner, post in
                owner.presentDeleteAlert(post: post)
            }
            .disposed(by: disposeBag)

        feedVC.cameraButtonTapped
            .drive(with: self) { owner, _ in
                owner.presentCameraActionSheet()
            }
            .disposed(by: disposeBag)

        calendarVC.calendarImageTapped
            .drive(with: self) { owner, payload in
                owner.routeTrigger?.onCalendarImageTapped?(payload.0, payload.1)
            }
            .disposed(by: disposeBag)
        
        // currentPageRelay의 값(페이지 index)이 변경되면 화면을 전환한다
        currentPageDriver
            .distinctUntilChanged()
            .drive(with: self) { vc, page in
                let currentIndex = vc.pageViewController.viewControllers
                    .flatMap { $0.first }
                    .flatMap { vc.dataViewControllers.firstIndex(of: $0) }
                ?? 0
                let direction: UIPageViewController.NavigationDirection = page >= currentIndex ? .forward : .reverse
                vc.pageViewController.setViewControllers([vc.dataViewControllers[page]],
                                                         direction: direction,
                                                         animated: true)
            }
            .disposed(by: disposeBag)
    }

    private func presentCameraActionSheet() {
        let alert = AlertFactory.makeAlert(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet,
            actions: [
                UIAlertAction(title: LocalizationKey.homeFeedCameraActionCamera.localized, style: .default) { [weak self] _ in
                    self?.routeTrigger?.onCameraTapped?(.camera)
                },
                UIAlertAction(title: LocalizationKey.homeFeedCameraActionAlbum.localized, style: .default) { [weak self] _ in
                    self?.routeTrigger?.onCameraTapped?(.album)
                },
                UIAlertAction(title: LocalizationKey.commonCancel.localized, style: .cancel)
            ]
        )
        present(alert, animated: true)
    }

    private func presentDeleteAlert(post: Post) {
        guard feedVC.reactor?.currentState.user?.uid == post.userId else { return }

        let alert = AlertFactory.makeAlert(
            title: LocalizationKey.homeFeedDeleteAlertTitle.localized,
            message: LocalizationKey.homeFeedDeleteAlertMessage.localized,
            preferredStyle: .alert,
            actions: [
                UIAlertAction(title: LocalizationKey.commonDelete.localized, style: .destructive) { [weak self] _ in
                    self?.feedVC.reactor?.action.onNext(.deleteConfirmed(post))
                },
                UIAlertAction(title: LocalizationKey.commonCancel.localized, style: .cancel)
            ]
        )
        present(alert, animated: true)
    }
}

//#Preview {
//    let vc = HomeViewController(reactor: HomeReactor())
//    UINavigationController(rootViewController: vc)
//    
//}

extension HomeViewController: UIPageViewControllerDelegate {
    
    /// 페이지 전환 애니메이션이 완료되었을 때 호출됩니다.
    ///
    /// - Parameters:
    ///   - pageViewController: 현재 페이지를 관리하는 UIPageViewController
    ///   - finished: 애니메이션이 정상적으로 끝났는지 여부
    ///   - previousViewControllers: 전환 이전에 표시되던 ViewController 배열
    ///   - completed: 사용자의 스와이프가 완료되어 실제 페이지 전환이 확정되었는지 여부
    ///
    /// - Note:
    ///   - `finished`는 애니메이션 종료 여부
    ///   - `completed`는 실제 페이지 변경 여부
    ///   - 사용자가 스와이프하다가 취소하면 `completed == false`
    ///
    /// - Important:
    ///   반드시 `completed == true`일 때만 현재 페이지를 업데이트해야 합니다.
    ///
    /// - Example:
    ///   현재 페이지 인덱스를 RxRelay, Combine, State 등으로 전달할 때 사용
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard
            completed, // 실제 페이지 전환이 완료된 경우
            let vc = pageViewController.viewControllers?.first, // 현재 표시 중인 VC
            let index = dataViewControllers.firstIndex(of: vc)  // 현재 index 찾기
        else { return }
        
        // 현재 페이지 index를 전달한다.
        currentPageRelay.accept(index)
    }
}

extension HomeViewController: UIPageViewControllerDataSource {
    
    /// 현재 ViewController 기준으로 "이전 페이지"를 요청할 때 호출됩니다.
    ///
    /// - Parameters:
    ///   - pageViewController: 페이지를 관리하는 컨트롤러
    ///   - viewController: 현재 표시되고 있는 ViewController
    ///
    /// - Returns:
    ///   - 이전 페이지에 해당하는 ViewController
    ///   - 첫 번째 페이지라면 nil 반환 (더 이상 이전 페이지 없음)
    ///
    /// - Note:
    ///   - 사용자가 오른쪽으로 스와이프할 때 호출됩니다.
    ///   - index를 기반으로 이전 VC를 계산하는 것이 일반적입니다.
    ///
    /// - Important:
    ///   배열 범위를 벗어나지 않도록 반드시 index 체크 필요
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        // 현재 index 찾기
        guard let index = dataViewControllers.firstIndex(of: viewController), index > 0 else {
            return nil
        }
        // 이전 페이지 반환
        return dataViewControllers[index - 1]
    }
    
    /// 현재 ViewController 기준으로 "다음 페이지"를 요청할 때 호출됩니다.
    ///
    /// - Parameters:
    ///   - pageViewController: 페이지를 관리하는 컨트롤러
    ///   - viewController: 현재 표시되고 있는 ViewController
    ///
    /// - Returns:
    ///   - 다음 페이지에 해당하는 ViewController
    ///   - 마지막 페이지라면 nil 반환 (더 이상 다음 페이지 없음)
    ///
    /// - Note:
    ///   - 사용자가 왼쪽으로 스와이프할 때 호출됩니다.
    ///
    /// - Important:
    ///   마지막 인덱스를 초과하지 않도록 반드시 체크해야 합니다.
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        // 현재 index 찾기
        guard let index = dataViewControllers.firstIndex(of: viewController),
              index < dataViewControllers.count - 1 else {
            return nil
        }
        // 다음 페이지 반환
        return dataViewControllers[index + 1]
    }
}

extension HomeViewController: GestureDelegate {
    func calendarDidStartGesture() {
        pageScrollView?.isScrollEnabled = false
    }
    
    func calendarDidEndGesture() {
        pageScrollView?.isScrollEnabled = true
    }
}


/// 3초 후에 completion을 호출하는 비동기 함수
/// - Parameter completion: 작업 완료 후 실행될 escaping 클로저
/*
 [weak self] end in
 guard let self = self else {
     end()
     return
 }
 self.wait3Seconds(completion: end)
 */
