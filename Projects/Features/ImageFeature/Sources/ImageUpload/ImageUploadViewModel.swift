//
//  ImageUploadViewModel.swift
//  ImageFeature
//
//  Created by 김동현 on 2/20/26.
//

import ImageFeatureInterface
import RxSwift
import UIKit
import Core
import Domain
import RxCocoa
import RxRelay

final class ImageUploadViewModel: UploadViewModelType {
    
    @Dependency private var groupUsecase: GroupUsecaseProtocol
    
    let disposeBag = DisposeBag()
    
    // MARK: - Coordinator Trigger
    var onUploadCompleted: (() -> Void)?
    
    let image: UIImage
    
    struct Input {
        let uploadButtonTapped: Observable<Void>
    }
    
    struct Output {
        let isUploading: Driver<Bool>
    }
    
    init(image: UIImage) {
        self.image = image
    }
    
    func transform(input: Input) -> Output {
        
        let uploading = PublishRelay<Bool>()
        
        input.uploadButtonTapped
            .flatMapLatest { [weak self] _ -> Observable<Void> in
                guard let self else { return .empty() }
                
                uploading.accept(true)

                return self.groupUsecase
                    .uploadImageAndUploadPost(image: self.image)
                    .do(
                        onNext: { _ in uploading.accept(false) },
                        onError: { _ in uploading.accept(false) },
                    )
            }
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, _ in
                owner.onUploadCompleted?()
            }
            .disposed(by: disposeBag)

        return Output(isUploading: uploading.asDriver(onErrorJustReturn: false))
    }

}



//
//func transform(input: Input) -> Output {
//    input.uploadButtonTapped
//        .flatMapLatest { [weak self] _ -> Observable<Void> in
//            guard let self = self else { return .empty() }
//            return self.groupUsecase
//                .uploadImageAndUploadPost(image: self.image)
//                .asObservable()
//        }
//        .asDriver(onErrorJustReturn: ())
//        .drive(with: self, onNext: { owner, _ in
//            owner.onUploadCompleted?()
//        })
//        .disposed(by: disposeBag)
//    return Output()
//}
