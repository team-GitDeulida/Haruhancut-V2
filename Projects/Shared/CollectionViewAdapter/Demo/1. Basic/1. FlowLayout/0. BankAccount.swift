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

/// 계좌 목록의 섹션별 제목, 설명, 계좌 데이터를 표현합니다.
struct BankAccountSection {
    let id: String
    let title: String
    let description: String
    let accounts: [BankAccount]
}

extension BankAccountSection {
    static let sample: [BankAccountSection] = [
        BankAccountSection(
            id: "myAccounts",
            title: "내 계좌",
            description: "기본 UICollectionView로 계좌 목록을 표시합니다.",
            accounts: BankAccount.sample
        ),
        BankAccountSection(
            id: "sampleAccounts",
            title: "샘플 계좌",
            description: "두 번째 섹션의 계좌 목록입니다.",
            accounts: [
                BankAccount(
                    id: UUID(),
                    name: "모임 통장",
                    balance: 56_700
                ),
                BankAccount(
                    id: UUID(),
                    name: "여행 적금",
                    balance: 340_000
                )
            ]
        )
    ]
}
