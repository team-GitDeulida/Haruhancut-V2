//
//  SignInViewController.swift
//  AuthFeature
//
//  Created by 김동현 on 1/12/26.
//

import UIKit

final class SignUpViewController: UIViewController {
    
    enum Step {
        case nickname
        case birthday
        case profile
    }
    
    // MARK: - Properties
    private let customView = SignUpView()
    private var currentStep: Step = .nickname
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = customView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }
    
    private func bindViewModel() {
        customView.onNextTapped = { [weak self] in
            guard let self else { return }
            self.handleNext()
        }
        
        customView.onBackTapped = { [weak self] in
            guard let self else { return }
            self.handleBack()
        }
        
        customView.onSkipTapped = { [weak self] in
            guard let self else { return }
            self.finishSignUp()
        }
    }
    
    private func pageIndex(for step: Step) -> Int {
        switch step {
        case .nickname: return 0
        case .birthday: return 1
        case .profile:  return 2
        }
    }
    
    private func handleNext() {
        switch currentStep {
        case .nickname:
            currentStep = .birthday
            customView.move(to: pageIndex(for: currentStep))

        case .birthday:
            currentStep = .profile
            customView.move(to: pageIndex(for: currentStep))

        case .profile:
            finishSignUp()
        }
    }
    
    private func handleBack() {
        switch currentStep {

        case .nickname:
            navigationController?.popViewController(animated: true)

        case .birthday:
            currentStep = .nickname
            customView.move(to: pageIndex(for: currentStep))

        case .profile:
            currentStep = .birthday
            customView.move(to: pageIndex(for: currentStep))
        }
    }

    
    private func finishSignUp() {
        // 회원가입 완료 처리
    }
}

#Preview {
    SignUpViewController()
}
