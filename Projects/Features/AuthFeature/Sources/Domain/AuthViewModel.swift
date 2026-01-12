//
//  SignInViewController.swift
//  AuthFeature
//
//  Created by 김동현 on 1/12/26.
//

import UIKit
import AuthFeatureInterface

final class AuthViewModel: AuthViewModelType {
    var onAuthCompleted: (() -> Void)?
    
    private let useCase: AuthUseCase
    
    init(useCase: AuthUseCase) {
         self.useCase = useCase
     }
}





