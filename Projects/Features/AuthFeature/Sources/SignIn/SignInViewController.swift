//
//  SignInViewController.swift
//  AuthFeature
//
//  Created by 김동현 on 1/12/26.
//

import UIKit
import AuthFeatureInterface
import ThirdPartyLibs

final class SignInViewController: UIViewController {

    private let viewModel: AuthViewModelType
    private let customView = SignInView()

    init(viewModel: AuthViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        customView.animationView.play()
    }
    
    override func loadView() {
        self.view = customView
    }
    
    private func bindViewModel() {
        let input = AuthViewModel.Input(kakaoButtonTapped: customView.kakaoLoginButton.rx.tap.asObservable(),
                                        appleButtonTapped: customView.appleLoginButton.rx.tap.asObservable())
        
//        let output = viewModel.
    }
}




