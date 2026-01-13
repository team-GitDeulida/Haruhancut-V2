//
//  AuthRepositoryProtocol.swift
//  Domain
//
//  Created by 김동현 on 1/12/26.
//

import Foundation
import RxSwift
import Core

public protocol AuthRepositoryProtocol {
    func loginWithKakao() -> Observable<Result<String, LoginError>>
}
