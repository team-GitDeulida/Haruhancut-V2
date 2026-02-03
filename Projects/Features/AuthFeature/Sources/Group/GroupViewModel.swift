//  GroupViewModel.swift
//  AuthFeature
//
//  Created by 김동현 on 2/3/26.
//

import UIKit
import RxSwift
import AuthFeatureInterface
import RxCocoa
import Core

final class GroupViewModel: GroupViewModelType {
    
    var onGroupMakeOrJoinSuccess: (() -> Void)?
    
    struct Input {
        // Select
        let enterButtonTapped: Observable<Void>
        let hostButtonTapped: Observable<Void>
        
        // Host
        let groupNameText: Observable<String>
        let hostEndTapped: Observable<Void>
        
        // Enter
        let invideCodeText: Observable<String>
        let enterEndTapped: Observable<Void>
    }
    
    struct Output {
        let hostResult: Driver<Result<String, GroupError>>
        let joinResult: Driver<Result<String, GroupError>>
    }
    
    func transform(input: Input) -> Output {
        let hostResult = input.hostButtonTapped
          
        
        return Output(hostResult: .just(.success("")),
                      joinResult: .just(.success("")))
    }
    
}
