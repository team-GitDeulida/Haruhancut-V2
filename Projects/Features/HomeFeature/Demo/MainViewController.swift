//
//  MainViewController.swift
//  HomeDemo
//
//  Created by 김동현 on 
//

//import UIKit
//
//final class MainViewController: UIViewController {
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .systemBackground
//        setupUI()
//    }
//
//    private func setupUI() {
//        let label = UILabel()
//        label.text = "Home Demo"
//        label.font = .systemFont(ofSize: 24, weight: .bold)
//        label.textAlignment = .center
//        label.translatesAutoresizingMaskIntoConstraints = false
//
//        view.addSubview(label)
//
//        NSLayoutConstraint.activate([
//            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
//        ])
//    }
//}


//
//  MainViewController.swift
//  HomeDemo
//

import UIKit
import RxSwift
import RxCocoa

final class MainViewController: UIViewController {

    private let disposeBag = DisposeBag()

    private let label = UILabel()
    private let button = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        bind()
    }

    private func setupUI() {

        label.text = "Tap Button"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center

        button.setTitle("Tap", for: .normal)

        label.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)
        view.addSubview(button)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            button.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func bind() {

        // ControlEvent → Observable
        let tap = button.rx.tap

        // Observable → Driver
        let textDriver = tap
            .map { "Tapped at \(Date())" }
            .asDriver(onErrorJustReturn: "Error")

        // Driver → Binder
        textDriver
            .drive(label.rx.text)
            .disposed(by: disposeBag)
    }
}
