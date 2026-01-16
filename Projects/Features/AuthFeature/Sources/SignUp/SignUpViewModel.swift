//
//  SignUpViewModel.swift
//  AuthFeature
//
//  Created by 김동현 on 1/16/26.
//

import Foundation
import AuthFeatureInterface

final class SignUpViewModel: SignUpViewModelType {
    
    struct Input {}
    
    struct Output {}
    
    var onSignUpSuccess: (() -> Void)?
}

extension SignUpViewModel {
    func transform(input: Input) -> Output {
        return Output()
    }
}
