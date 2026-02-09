//
//  Empty.swift
//  Profile
//
//  Created by 김동현 on 
//

import UIKit
import ProfileFeatureInterface
import DSKit
import Core

final class ProfileViewController: UIViewController, PopableViewController {
    var onPop: (() -> Void)?
    
    let viewModel: ProfileViewModel
    var onDisappear: (() -> Void)?
    
    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if isMovingFromParent {
            onPop?()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        view.backgroundColor = .background
        
        let label = UILabel()
        label.text = "Profile Demo"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

final class ProfileViewModel: ProfileViewModelType {
    func transform(input: Int) -> Int {
        0
    }
    
    typealias Input = Int
    
    typealias Output = Int
    
    
}
