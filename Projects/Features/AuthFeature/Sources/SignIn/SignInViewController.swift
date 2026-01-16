//
//  SignInViewController.swift
//  AuthFeature
//
//  Created by 김동현 on 1/12/26.
//

import UIKit
import AuthFeatureInterface
import RxSwift

final class SignInViewController: UIViewController {
    
    // MARK: - Properties
    let disposeBag = DisposeBag()
    public var signInViewModel: SignInViewModel
    private let customView = SignInView()

    // MARK: - Init
    init(signInViewModel: SignInViewModel) {
        self.signInViewModel = signInViewModel
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }
    
    private func bindViewModel() {
        let input = SignInViewModel.Input(kakaoLoginButtonTapped: customView.kakaoLoginButton.rx.tap.asObservable(),
                                          appleLoginButtonTapped: customView.appleLoginButton.rx.tap.asObservable())
        
        let output = signInViewModel.transform(input: input)
        output.loginResult
            .drive(onNext: { result in
                print("loginResult: \(result)")
            })
            .disposed(by: disposeBag)
    }
}




