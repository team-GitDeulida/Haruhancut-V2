//
//  SignInViewController.swift
//  AuthFeature
//
//  Created by 김동현 on 1/12/26.
//

import UIKit
import AuthFeatureInterface
import Domain

final class AuthViewModel: AuthViewModelType {
    var onAuthCompleted: (() -> Void)?
    
    private let useCase: AuthUsecaseProtocol
    
    init(useCase: AuthUsecaseProtocol) {
         self.useCase = useCase
     }
}
