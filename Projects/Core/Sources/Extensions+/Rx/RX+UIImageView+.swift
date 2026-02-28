//
//  RXUIImage.swift
//  Core
//
//  Created by 김동현 on 2/27/26.
//

import UIKit
import Kingfisher
import RxSwift

// MARK: - UIImageView + KingFisher + Rx 어댑터
/*
 UIImageView에서 UIImage로 바인딩하는 RX는 제공된다
 하지만 URL(String)으로 바인딩해서 자동 다운로드까지 해주는 연산자는 기본적으로 재공하지 않는다
 */
public extension UIImageView {

    /// Kingfisher를 감싸는 프로젝트 전용 이미지 로딩 메서드
    func setImage(with url: URL?,
                  placeholder: UIImage? = nil,
                  forceRefresh: Bool = false
    ) {
        
        self.kf.cancelDownloadTask()
        
        guard let url else {
            self.image = placeholder
            return
        }

        let options: KingfisherOptionsInfo = forceRefresh ? [.forceRefresh] : []

        self.kf.setImage(
            with: url,
            placeholder: placeholder,
            options: options
        )
        
    }
}

public extension Reactive where Base: UIImageView {

    /// String URL을 바로 UIImageView에 바인딩 가능하게 만든다
    /// 내부에서 String → URL 변환 후 setImage 호출
    /// MainThread 보장 (Binder 특성)
    /// .drive(imageView.rx.imageURL) 로 Observable이 방출하는 값을 imageView에 연결한다
    var imageURL: Binder<String?> {
        Binder(base) { imageView, urlString in
            let url = urlString.flatMap { URL(string: $0) }
            imageView.setImage(with: url)
        }
    }
}
