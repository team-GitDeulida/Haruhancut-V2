//
//  Comment.swift
//  Domain
//
//  Created by 김동현 on 1/20/26.
//

import Foundation

public struct Comment: Encodable {
    public let commentId: String
    public let userId: String
    public let nickname: String
    public var profileImageURL: String?
    public let text: String
    public let createdAt: Date
    
    public init(commentId: String, userId: String, nickname: String, profileImageURL: String? = nil, text: String, createdAt: Date) {
        self.commentId = commentId
        self.userId = userId
        self.nickname = nickname
        self.profileImageURL = profileImageURL
        self.text = text
        self.createdAt = createdAt
    }
}
