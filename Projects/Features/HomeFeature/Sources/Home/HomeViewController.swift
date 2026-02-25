//
//  HomeViewController.swift
//  HomeFeature
//
//  Created by 김동현 on 1/16/26.
//

import UIKit
import RxSwift
import RxCocoa
import DSKit

final class HomeViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    private let viewModel: HomeViewModel
    private let currentPageRelay = BehaviorRelay<Int>(value: 0)
    private var dataViewControllers: [UIViewController] { [feedVC, calendarVC] }
    
    // MARK: - UI Component
    private let segmentedBar: CustomSegmentedBarView = {
        let segment = CustomSegmentedBarView(items: ["피드", "캘린더"])
        return segment
    }()
    
    private lazy var feedVC: FeedViewController = {
        let vc = FeedViewController(homeViewModel: viewModel)
        return vc
    }()
    
    private lazy var calendarVC: CalendarViewController = {
        let vc = CalendarViewController(homeViewModel: viewModel)
        return vc
    }()
    
    private lazy var pageViewController: UIPageViewController = {
        let vc = UIPageViewController(transitionStyle: .scroll,
                                      navigationOrientation: .horizontal)
        vc.delegate = self
        vc.dataSource = self
        return vc
    }()
    
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
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
        
        /// 우측 네비게이션 버튼
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "person.fill"),
            style: .plain,
            target: nil,
            action: nil)
        
        /// 자식 화면에서 뒤로가기
        let backItem = UIBarButtonItem()
        backItem.title = "홈으로"
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
    
    private func bind() {
        
        // left navi btn
        self.navigationItem.leftBarButtonItem?.rx.tap
            .withUnretained(self)
            .subscribe(onNext: { vc, _ in
                print("left")
            })
            .disposed(by: disposeBag)
        
        // right navi btn
        self.navigationItem.rightBarButtonItem?.rx.tap
            .subscribe(onNext: {
                self.viewModel.onProfileTapped?()
            })
            .disposed(by: disposeBag)
        
        // SegmentedControl -> Page
        segmentedBar.segmentedControl.rx.selectedSegmentIndex
            .bind(to: currentPageRelay)
            .disposed(by: disposeBag)
        
        // Page -> SegmentedControl
        currentPageRelay
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .subscribe(onNext: { vc, index in
                vc.segmentedBar.segmentedControl.selectedSegmentIndex = index
                vc.segmentedBar.moveUnderline(animated: true)
            })
            .disposed(by: disposeBag)
        
        // Page -> UIPageViewController
        currentPageRelay
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .subscribe(onNext: { vc, page in
                let currentIndex = vc.pageViewController.viewControllers
                    .flatMap { $0.first }
                    .flatMap { vc.dataViewControllers.firstIndex(of: $0) }
                ?? 0
                let direction: UIPageViewController.NavigationDirection = page >= currentIndex ? .forward : .reverse
                self.pageViewController.setViewControllers([self.dataViewControllers[page]],
                                                           direction: direction,
                                                           animated: true)
            })
            .disposed(by: disposeBag)
        
        
        
        // MARK: - FeedVC
        // , calendarVC.refreshTriggered도 추가예정
        let refreshTapped = Observable.merge(feedVC.refreshTriggered)

        let input = HomeViewModel.Input(viewDidLoad: .just(()),
                                        refreshTapped: refreshTapped,
                                        imageTapped: feedVC.imageTapped,
                                        longPressed: feedVC.longPressed,
                                        cameraButtonTapped: feedVC.cameraButtonTapped,
                                        deleteConfirmed: feedVC.deleteConfirmed)
        
        let output = viewModel.transform(input: input)
        feedVC.setOutput(output)
        calendarVC.setOutput(output)
    }
}

extension HomeViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard
            completed,
            let vc = pageViewController.viewControllers?.first,
            let index = dataViewControllers.firstIndex(of: vc)
        else { return }
        currentPageRelay.accept(index)
    }
}

extension HomeViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = dataViewControllers.firstIndex(of: viewController), index > 0 else {
            return nil
        }
        return dataViewControllers[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = dataViewControllers.firstIndex(of: viewController),
              index < dataViewControllers.count - 1 else {
            return nil
        }
        return dataViewControllers[index + 1]
    }
}

/*
class HomeViewController: UIViewController {
    
    private let viewModel: HomeViewModel
    private let logoutButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .green
        setupLogoutButton()
    }
    
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        bind()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLogoutButton() {
        logoutButton.setTitle("로그아웃", for: .normal)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoutButton)
        
        NSLayoutConstraint.activate([
            logoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoutButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func bind() {
        let input = HomeViewModel.Input(logoutButtonTapped: logoutButton.rx.tap.asObservable())
    
        _ = viewModel.transform(input: input)
    }
}
*/
