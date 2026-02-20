//
//  CameraView.swift
//  ImageFeature
//
//  Created by 김동현 on 2/15/26.
//

import UIKit
import DSKit

final class CameraView: UIView {
    
    // MARK: - UI Component
    let cameraView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = true
        return view
    }()
    
    let cameraButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "button.programmable"), for: .normal)
        btn.tintColor = .mainWhite
        btn.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 70.scaled), forImageIn: .normal)
        btn.imageView?.contentMode = .scaleAspectFit
        return btn
    }()
    
    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Configures view appearance and adds subviews required for the camera UI.
    /// 
    /// Sets the view's background color and adds `cameraView` and `cameraButton` as subviews, disabling their `translatesAutoresizingMaskIntoConstraints` so Auto Layout constraints can be applied.
    private func setupUI() {
        backgroundColor = .background
        [cameraView, cameraButton].forEach {
            self.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    /// Configures and activates Auto Layout constraints for the view's subviews.
    /// 
    /// Positions `cameraView` near the top center of the safe area with a 20-point leading inset and enforces a square aspect ratio (height equal to width). Positions `cameraButton` centered horizontally near the bottom of the safe area.
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // MARK: - cameraView
            // 위치
            cameraView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: 150),
            cameraView.centerXAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerXAnchor),
            
            // 크기
            cameraView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            cameraView.heightAnchor.constraint(equalTo: cameraView.widthAnchor),
            
            // MARK: - cameraBtn
            cameraButton.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: -50.scaled),
            cameraButton.centerXAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerXAnchor),
            
        ])
    }
    
}