//  ImagePreViewController.swift
//  Haruhancut
//
//  Created by 김동현 on 6/19/25.
//

import UIKit

public final class ImagePreViewController: UIViewController {
    private let customView: ImagePreView
    
    // MARK: - Initializer
    public init(imageURL: String) {
        self.customView = ImagePreView(imageURL: imageURL)
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - LifeCycle
    public override func loadView() {
        self.view = customView
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        addTarget()
    }
    
    // MARK: - addTarget
    private func addTarget() {
        customView.scrollView.delegate = self
        customView.closeButton.addTarget(self, action: #selector(closePreview), for: .touchUpInside)
        customView.saveButton.addTarget(self, action: #selector(savePreview), for: .touchUpInside)
    }
}

public extension ImagePreViewController {
    @objc private func closePreview() {
        dismiss(animated: true)
    }
    
    @objc private func savePreview() {
        guard let image = customView.imageView.image else {
            return
        }
        
        // 앨범에 사진 저장
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        // 저장 알림 표시
        let alert = AlertFactory.makeAlert(title: "사진 저장", message: "사진이 앨범에 저장되었습니다.", actions: [
            UIAlertAction(title: "확인", style: .default)
        ])
        self.present(alert, animated: true)
    }
}

extension ImagePreViewController: UIScrollViewDelegate {
    // 줌 대상 지정
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return customView.imageView
    }
}

//#Preview {
//    ImagePreViewController(image: UIImage())
//}
