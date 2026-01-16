//
//  SignInViewController.swift
//  AuthFeature
//
//  Created by 김동현 on 1/12/26.
//

import UIKit

final class SignUpViewController: UIViewController {
    
    // MARK: - Properties
    private let customView = GroupView()
    
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
 
    }
}
