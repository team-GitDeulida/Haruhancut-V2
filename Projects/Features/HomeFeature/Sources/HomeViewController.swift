//
//  HomeViewController.swift
//  HomeFeature
//
//  Created by 김동현 on 1/16/26.
//

import UIKit
import RxSwift
import RxCocoa

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
