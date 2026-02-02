//
//  HomeViewModel.swift
//  HomeFeature
//
//  Created by 김동현 on 1/16/26.
//

import Foundation
import HomeFeatureInterface
import RxSwift

final class HomeViewModel: HomeViewModelType {
    
    private let disposeBag = DisposeBag()
    
    var onLogoutTapped: (() -> Void)?
    var onImageTapped: (() -> Void)?
    
    struct Input {
        let logoutButtonTapped: Observable<Void>
    }
    
    struct Output {}
    
    public init() {}
    
    func transform(input: Input) -> Output {
        // bind: 값을 UI나 Binder로 꽂을 때
        // Driver는 UI용
        input.logoutButtonTapped
            .subscribe(onNext: { [weak self] in
                self?.onLogoutTapped?()
            })
            .disposed(by: disposeBag)
        
        return Output()
    }
}
