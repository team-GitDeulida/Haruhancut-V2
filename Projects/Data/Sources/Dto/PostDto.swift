//
//  PostDto.swift
//  Data
//
//  Created by 김동현 on 1/20/26.
//

import Foundation
import Domain

public struct PostDTO: Codable {
    let postId: String?
    let userId: String?
    let nickname: String?
    let profileImageURL: String?
    let imageURL: String?
    let createdAt: String?
    let likeCount: Int?
    let comments: [String: CommentDTO]?
}

extension PostDTO {
    public func toModel() -> Post? {
        let formatter = ISO8601DateFormatter()
        
        guard
            let postId = postId,
            let userId = userId,
            let nickname = nickname,
            let imageURL = imageURL,
            let createdAtStr = createdAt,
            let createdAt = formatter.date(from: createdAtStr),
            let likeCount = likeCount
        else {
            return nil
        }
        
        // let comments = self.comments?.compactMap { $0.toModel() } ?? []
        let commentList = self.comments?.compactMapValues { $0.toModel() } ?? [:]

        return Post(
            postId: postId,
            userId: userId,
            nickname: nickname,
            profileImageURL: profileImageURL,
            imageURL: imageURL,
            createdAt: createdAt,
            likeCount: likeCount,
            comments: commentList
        )
    }
}

extension Post {
    public func toDTO() -> PostDTO {
        let formatter = ISO8601DateFormatter()
        let commentDTOs = Dictionary(uniqueKeysWithValues: comments.map { key, comment in
                    (key, comment.toDTO())
                })
        
        return PostDTO(
            postId: postId,
            userId: userId,
            nickname: nickname,
            profileImageURL: profileImageURL,
            imageURL: imageURL,
            createdAt: formatter.string(from: createdAt),
            likeCount: likeCount,
            comments: commentDTOs
        )
    }
}
