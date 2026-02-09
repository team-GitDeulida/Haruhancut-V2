//
//  CalendarViewController.swift
//  HomeFeature
//
//  Created by 김동현 on 2/9/26.
//

import UIKit

final class CalendarViewController: UIViewController {
    
    private let homeViewModel: HomeViewModel
    private let customView = CalendarView()
    
    // MARK: - Initializer
    init(homeViewModel: HomeViewModel) {
        self.homeViewModel = homeViewModel
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
        bindViewModel()
    }
    
    // MARK: - Bindings
    private func bindViewModel() {
        
    }
}
