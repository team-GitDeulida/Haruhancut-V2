//
//  ViewModelType.swift
//  Core
//
//  Created by 김동현 on 1/15/26.
//

import Foundation

public protocol ViewModelType {
    associatedtype Input
    associatedtype Output
    
    func transform(input: Input) -> Output
}
