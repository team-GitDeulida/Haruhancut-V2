//
//  MemberViewController.swift
//  MemberFeature
//
//  Created by 김동현 on 3/4/26.
//

import UIKit

final class MemberViewController: UIViewController {
    private let viewModel: MemberViewModel
    private let customView = MemberView()
    
    init(viewModel: MemberViewModel) {
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
        view.backgroundColor = .systemBackground
    }
}
