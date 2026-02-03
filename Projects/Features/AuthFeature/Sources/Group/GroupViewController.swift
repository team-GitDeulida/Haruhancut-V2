//  GroupViewController.swift
//  AuthFeature
//
//  Created by 김동현 on 2/3/26.
//

import UIKit
import RxSwift

// MARK: - (C)GroupViewController
final class GroupViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    private let viewModel: GroupViewModel
    private let customView = GroupView()
    
    // MARK: - Initializer
    init(viewModel: GroupViewModel) {
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
    }   
    
    // MARK: - Bindings
    private func bindViewModel() {
        
        let input = GroupViewModel.Input(enterButtonTapped: customView.groupSelectView.enterButton.rx.tap.asObservable(),
                                         hostButtonTapped: customView.groupSelectView.hostButton.rx.tap.asObservable(),
                                         groupNameText: customView.groupHostView.textField.rx.text.orEmpty.asObservable(),
                                         hostEndTapped: customView.groupHostView.endButton.rx.tap.asObservable(),
                                         invideCodeText: customView.groupEnterView.textField.rx.text.orEmpty.asObservable(),
                                         enterEndTapped: customView.groupEnterView.endButton.rx.tap.asObservable())
        
        let output = viewModel.transform(input: input)
        
        output.step
            .drive(onNext: { [weak self] step in
                switch step {
                case .host:
                    self?.customView.move(to: 0)
                case .enter:
                    self?.customView.move(to: 1)
                case .select:
                    self?.customView.move(to: 2)
                }
            })
            .disposed(by: disposeBag)
    }
}

#Preview {
    GroupViewController(viewModel: GroupViewModel())
}
