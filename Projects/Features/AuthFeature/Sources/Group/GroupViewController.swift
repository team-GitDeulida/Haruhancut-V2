//  GroupViewController.swift
//  AuthFeature
//
//  Created by 김동현 on 2/3/26.
//

import UIKit
import RxSwift

// MARK: - (C)GroupViewController
final class GroupViewController: UIViewController {
    
    typealias Step = GroupViewModel.Step
    
    let disposeBag = DisposeBag()
    private let viewModel: GroupViewModel
    private let customView = GroupView()
    
    private lazy var backButton: UIBarButtonItem = {
        UIBarButtonItem(image: UIImage(systemName: "chevron.left"),
                        style: .plain,
                        target: nil,
                        action: nil)
    }()
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBarAppearance()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // MARK: - Bindings
    private func bindViewModel() {
        
        let input = GroupViewModel.Input(backTapped: backButton.rx.tap.asObservable(),
                                         enterButtonTapped: customView.groupSelectView.enterButton.rx.tap.asObservable(),
                                         hostButtonTapped: customView.groupSelectView.hostButton.rx.tap.asObservable(),
                                         
                                         groupNameText: customView.groupHostView.textField.rx.text.orEmpty.asObservable(),
                                         hostReturnTapped: customView.groupHostView.textField.rx.controlEvent(.editingDidEndOnExit).asObservable(),
                                         hostEndTapped: customView.groupHostView.endButton.rx.tap.asObservable(),
                                         
                                         invideCodeText: customView.groupEnterView.textField.rx.text.orEmpty.asObservable(),
                                         enterReturnTapped: customView.groupEnterView.textField.rx.controlEvent(.editingDidEndOnExit).asObservable(),
                                         enterEndTapped: customView.groupEnterView.endButton.rx.tap.asObservable())
        
        let output = viewModel.transform(input: input)
        
        // 화면 이동
        output.step
            .distinctUntilChanged() // 이전과 같은 값이면 방출하지 않는다
            .scan((prev: Step.select, current: Step.select)) { acc, next in
                (prev: acc.current, current: next)
            }
            .drive(onNext: { [weak self] state in
                guard let self else { return }
                self.updateNavigationBar(step: state.current)

                switch state.current {
                case .select:
                    self.customView.show(
                        self.customView.groupSelectView,
                        direction: .backward
                    )

                case .host:
                    self.customView.show(
                        self.customView.groupHostView,
                        direction: .forward
                    )

                case .enter:
                    self.customView.show(
                        self.customView.groupEnterView,
                        direction: .forward
                    )
                }
            })
            .disposed(by: disposeBag)
        
        // 조건1: 키보드 return 입력 시 키보드 내려간다
        output.endEditingTrigger
            .emit(onNext: { [weak self] in
                guard let self = self else { return }
                self.view.endEditing(true)
            }).disposed(by: disposeBag)
        
        // 조건2: 그룹 생성 시 그룹 이름은 2글자 이상이어야 한다
        output.hostGroupNameValid
            .drive(with: self, onNext: { vc, isValid in
                vc.customView.groupHostView.endButton.isEnabled = isValid
            })
            .disposed(by: disposeBag)
        
        // 조건3: 그룹 입장 시 초대코드는 1자리 이상이어야 한다
        output.joinInviteCodeValid
            .drive(with: self, onNext: { vc, isValid in
                vc.customView.groupEnterView.endButton.isEnabled = isValid
            })
            .disposed(by: disposeBag)
        
        // 조건4: 뒤로가기 버튼 누를때는 키보드 애니메이션 비활성화(선택)
        backButton.rx.tap
            .withUnretained(self)
            .subscribe(onNext: { vc, _ in
                UIView.performWithoutAnimation {
                    vc.view.endEditing(true)
                }
            })
            .disposed(by: disposeBag)
    }
    
    // 네비게이션 설정1
    private func updateNavigationBar(step: Step) {
        switch step {
        case .select:
            navigationItem.leftBarButtonItem = nil
            navigationItem.title = "그룹 선택"
        case .host:
            navigationItem.leftBarButtonItem = backButton
            navigationItem.title = "그룹 만들기"
        case .enter:
            navigationItem.leftBarButtonItem = backButton
            navigationItem.title = "그룹 참가"
        }
    }
    
    // 네비게이션 설정2(스타일)
    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground() // 투명 원하면 clear
        
        // 배경색
        appearance.backgroundColor = .background   // 원하는 색으로
        
        // 타이틀 스타일
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.mainWhite,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        
        // 큰 타이틀 안 쓰면 생략 가능
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.mainWhite,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        // 뒤로가기 버튼 색상 (chevron + 텍스트)
        navigationController?.navigationBar.tintColor = .mainWhite
        
        // 적용
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
    }
}

//#Preview {
//    GroupViewController(viewModel: GroupViewModel())
//}
