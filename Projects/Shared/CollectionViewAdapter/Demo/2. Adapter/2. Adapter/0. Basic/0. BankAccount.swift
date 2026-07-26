//
//  BankAccount.swift
//  CollectionViewAdapter
//
//  Created by 김동현 on 7/21/26.
//

import Foundation

struct BankAccount {
    let id: UUID
    let name: String
    let balance: Int
    
    var balanceText: String {
        balance.formatted() + "원"
    }
}

extension BankAccount {
    static let sample: [BankAccount] = [
        BankAccount(
            id: UUID(),
            name: "00뱅크 통장",
            balance: 163_498
        ),
        BankAccount(
            id: UUID(),
            name: "입출금 통장",
            balance: 28_242
        ),
        BankAccount(
            id: UUID(),
            name: "저축 통장",
            balance: 221_842
        )
    ]
}
