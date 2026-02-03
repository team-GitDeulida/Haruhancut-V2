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

//final class HomeViewController: UIViewController {
//    
//    private let viewModel: HomeViewModel
//    
//    // MARK: - UI Component
//    private let segmentedBar: CustomSegmentedBarView = {
//        let segment = CustomSegmentedBarView(items: ["피드", "캘린더"])
//        return segment
//    }()
//    
//    private let pageViewController: UIPageViewController = {
//        let vc = UIPageViewController(transitionStyle: .scroll,
//                                      navigationOrientation: .horizontal)
//        vc.setViewControllers([],
//                              direction: .forward,
//                              animated: true)
//        return vc
//    }()
//    
//    init(viewModel: HomeViewModel) {
//        self.viewModel = viewModel
//        super.init(nibName: nil, bundle: nil)
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        self.view.backgroundColor = .green
//    }
//}
//




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
