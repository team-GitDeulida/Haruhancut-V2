//
//  Result.swift
//  Core
//
//  Created by 김동현 on 2/3/26.
//

import Foundation

public extension Result {
    func mapToVoid() -> Result<Void, Failure> {
        map { _ in () }
    }
}
