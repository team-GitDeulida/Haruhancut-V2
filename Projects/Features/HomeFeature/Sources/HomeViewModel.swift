//
//  HomeViewModel.swift
//  HomeFeature
//
//  Created by 김동현 on 1/16/26.
//

import Foundation
import HomeFeatureInterface

final class HomeViewModel: HomeViewModelType {
    var onImageTapped: (() -> Void)?
    
    struct Input {}
    
    struct Output {}
    
    public init() {}
    
    func transform(input: Input) -> Output {
        return Output()
    }
}
