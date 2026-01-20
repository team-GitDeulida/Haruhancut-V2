//
//  CommentDto.swift
//  Data
//
//  Created by 김동현 on 1/20/26.
//

import Foundation
import Domain

public struct CommentDTO: Codable {
    public let commentId: String?
    public let userId: String?
    public let nickname: String?
    public let profileImageURL: String?
    public let text: String?
    public let createdAt: String?
}

extension Comment {
    public func toDTO() -> CommentDTO {
        let formatter = ISO8601DateFormatter()
        return CommentDTO(
            commentId: commentId,
            userId: userId,
            nickname: nickname,
            profileImageURL: profileImageURL,
            text: text,
            createdAt: formatter.string(from: createdAt))
    }
}

extension CommentDTO {
    public func toModel() -> Comment? {
        let formatter = ISO8601DateFormatter()
        
        guard
            let commentId = commentId,
            let userId = userId,
            let nickname = nickname,
            let text = text,
            let createdAtStr = createdAt,
            let createdAt = formatter.date(from: createdAtStr)
        else {
            return nil
        }
        
        return Comment(
            commentId: commentId,
            userId: userId,
            nickname: nickname,
            profileImageURL: profileImageURL,
            text: text,
            createdAt: createdAt
        )
    }
}



