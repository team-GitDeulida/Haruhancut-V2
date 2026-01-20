//
//  Post.swift
//  Domain
//
//  Created by 김동현 on 1/20/26.
//

import Foundation

public struct Post: Encodable {
    public let postId: String
    public let userId: String           // 작성자 ID
    public let nickname: String         // 작성자 닉네임
    public let profileImageURL: String? // 작성자 프로필 사진
    public let imageURL: String
    public let createdAt: Date
    public let likeCount: Int
    public var comments: [String: Comment]
    public var isToday: Bool {
        Calendar.current.isDateInToday(createdAt)
    }
    
    public init(postId: String, userId: String, nickname: String, profileImageURL: String?, imageURL: String, createdAt: Date, likeCount: Int, comments: [String : Comment]) {
        self.postId = postId
        self.userId = userId
        self.nickname = nickname
        self.profileImageURL = profileImageURL
        self.imageURL = imageURL
        self.createdAt = createdAt
        self.likeCount = likeCount
        self.comments = comments
    }
}

extension Array where Element == Post {
    /*
     [
       "2025.06.17": [Post1, Post2],
       "2025.06.16": [Post3]
     ]
     */
    func groupedByDate() -> [String: [Post]] {
        return Dictionary(grouping: self) { post in
            post.createdAt.toDateKey()
        }
    }
}
