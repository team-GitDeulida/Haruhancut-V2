//  GroupViewModel.swift
//  AuthFeature
//
//  Created by 김동현 on 2/3/26.
//

import UIKit

final class GroupViewModel: GroupViewModelType {
    func transform(input: Int) -> Int {
        return 0
    }
    
    typealias Input = Int
    
    typealias Output = Int
    
    var onGroupMakeOrJoinSuccess: (() -> Void)?
    
    
}
