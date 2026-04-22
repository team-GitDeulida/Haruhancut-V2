//
//  NicknameEditViewController.swift
//  ProfileFeature
//
//  Created by 김동현 on 3/3/26.
//

import UIKit
import RxSwift
import RxCocoa
import DSKit

final class NicknameEditViewController: UIViewController {
    private let viewModel: NicknameEditViewModel
    private let customView = NicknameEditView()
    private let disposeBag = DisposeBag()
    
    // MARK: - Initializer
    init(viewModel: NicknameEditViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - LifeCycle
    override func loadView() {
        self.view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigation()
        bindViewModel()
    }
    
    // MARK: - setNavigation
    private func setNavigation() {
        let backItem = UIBarButtonItem()
        backItem.title = LocalizationKey.commonBack.localized
        backItem.tintColor = .mainWhite
        navigationItem.backBarButtonItem = backItem
        navigationController?.navigationBar.tintColor = .mainWhite
    }
    
    private func bindViewModel() {
        let input = NicknameEditViewModel.Input(nicknameText: customView.textField.rx.text.orEmpty.asObservable(),
                                                endButtonTapped: customView.endButton.rx.tap.asObservable())
        let output = viewModel.transform(input: input)
        
        /// 닉네임 유효성에 따라 버튼의 UI 상태 업데이트
        output.isNicknameValid
            .drive(with: self, onNext: { owner, isValid in
                owner.customView.endButton.isEnabled = isValid
                owner.customView.endButton.alpha = isValid ? 1 : 0.5
            })
            .disposed(by: disposeBag)
        
        /// retuen키 누르면 키보드 내려감
        customView.textField.rx.controlEvent(.editingDidEndOnExit)
            .asDriver()
            .drive(with: self, onNext: { owner, _ in
                owner.view.endEditing(true)
            })
            .disposed(by: disposeBag)
        }
   
    // MARK: - Bindings
    /*
    private func bindViewModel() {
        let input = LoginViewModel.NicknameEditInput(nickmaneText: customView.textField.rx.text.orEmpty.asObservable(),
                                                     endBtnTapped: customView.endButton.rx.tap.asObservable())
        
        let output = loginViewModel.transform(input: input)
        
        /// 닉네임 유효성에 따라 버튼의 UI 상태 업데이트
        output.isNicknameValid
            .drive(onNext: { [weak self] isValid in
                guard let self else { return }
                self.customView.endButton.isEnabled = isValid
                self.customView.endButton.alpha = isValid ? 1 : 0.5
            }).disposed(by: disposeBag)
        
        /// 닉네임 변경 성공시 뒤로가기, 실패시 알림 및 뒤로가기
        output.nicknameChangeResult
            .drive(onNext: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    self.navigationController?.popViewController(animated: true)
                case .failure(let error):
                    self.navigationController?.popViewController(animated: true)
                    AlertManager.showAlert(on: self, title: "에러: \(error)", message: "닉네임 변경 실패:\n\(error)")
                }
            }).disposed(by: disposeBag)
        
        /// return키 누르면 키보드 내려감
        customView.textField.rx.controlEvent(.editingDidEndOnExit)
            .asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                self.view.endEditing(true)
            }).disposed(by: disposeBag)
    }
     */
}
