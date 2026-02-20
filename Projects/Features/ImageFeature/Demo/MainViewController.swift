//
//  MainViewController.swift
//  ImageDemo
//
//  Created by 김동현 on 
//

import UIKit

final class MainViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }

    /// Creates and adds a centered title label displaying "Image Demo" to the view.
    /// 
    /// The label uses a bold system font at size 24, has centered text alignment, and is positioned at the view's center using Auto Layout constraints.
    private func setupUI() {
        let label = UILabel()
        label.text = "Image Demo"
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