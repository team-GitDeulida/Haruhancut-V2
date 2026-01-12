//
//  AuthRepositoryProtocol.swift
//  Domain
//
//  Created by 김동현 on 1/12/26.
//

import Foundation

public protocol AuthRepositoryProtocol {
    func signIn() async throws
}
