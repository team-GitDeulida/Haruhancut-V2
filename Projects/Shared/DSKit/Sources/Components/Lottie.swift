//
//  Lottie.swift
//  DSKit
//
//  Created by 김동현 on 1/13/26.
//

import UIKit
import ThirdPartyLibs

public final class HCLottieView: UIView {
    private let animationView: LottieAnimationView
    
    public init(
        animationName: String,
        loopMode: LottieLoopMode = .playOnce,
        contentMode: UIView.ContentMode = .scaleAspectFit
    ) {
        self.animationView = LottieAnimationView(name: animationName,
                                                 bundle: .module)
        super.init(frame: .zero)
        
        animationView.loopMode = loopMode
        animationView.contentMode = contentMode
        animationView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.topAnchor.constraint(equalTo: topAnchor),
            animationView.bottomAnchor.constraint(equalTo: bottomAnchor),
            animationView.leadingAnchor.constraint(equalTo: leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Control
    public func play() {
        animationView.play()
    }
    
    public func stop() {
        animationView.stop()
    }
    
    public func pause() {
        animationView.pause()
    }
}
