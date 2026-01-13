//
//  SignInViewController.swift
//  AuthFeature
//
//  Created by 김동현 on 1/12/26.
//

import UIKit
import AuthFeatureInterface
import Domain
import ThirdPartyLibs

final class AuthViewModel: AuthViewModelType {
    
    // MARK: - Properties
    private var disposeBag = DisposeBag()
    private let useCase: AuthUsecaseProtocol
    
    // MARK: - Coordinator
    var onAuthCompleted: (() -> Void)?
    
    // MARK: - Input
    public struct Input {
        let kakaoButtonTapped: Observable<Void>
        let appleButtonTapped: Observable<Void>
    }
    
    // MARK: - Output
    public struct Output {
        let loginResult: Driver<Result<Void, Error>>
    }
    
//    public func transform(input: Input) -> Output {
//        // MARK: - 카카오 로그인
//        let kakaoResult = input.kakaoButtonTapped
//            
//    }
    
    public init(useCase: AuthUsecaseProtocol) {
        self.useCase = useCase
    }
}

final class StubAuthViewModel: AuthViewModelType {
    var onAuthCompleted: (() -> Void)?
    
}
