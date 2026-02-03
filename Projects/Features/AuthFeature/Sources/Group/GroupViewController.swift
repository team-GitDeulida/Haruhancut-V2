//  GroupViewController.swift
//  AuthFeature
//
//  Created by 김동현 on 2/3/26.
//

import UIKit

// MARK: - (C)GroupViewController
final class GroupViewController: UIViewController {
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

    }
}

#Preview {
    GroupViewController(viewModel: GroupViewModel())
}
