//
//  SignInViewController.swift
//  AuthFeature
//
//  Created by 김동현 on 1/12/26.
//

import UIKit
import AuthFeatureInterface

protocol AuthRepositoryProtocol {
    func signIn() async throws
}

final class AuthRepository: AuthRepositoryProtocol {
    func signIn() async throws {
        print("🔐 SignIn API 호출")
    }
}
