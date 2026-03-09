//
//  GroupDto.swift
//  Data
//
//  Created by 김동현 on 1/20/26.
//

import Foundation
import Domain

public struct HCGroupDTO: Codable {
    public let groupId: String?
    public let groupName: String?
    public let createdAt: String?
    public let hostUserId: String?
    public let inviteCode: String?
    public let members: [String: String]?
    public var postsByDate: [String: [String: PostDTO]]? // postId가 key인 딕셔너리
    
    public init(groupId: String?, groupName: String?, createdAt: String?, hostUserId: String?, inviteCode: String?, members: [String : String]?, postsByDate: [String : [String : PostDTO]]? = nil) {
        self.groupId = groupId
        self.groupName = groupName
        self.createdAt = createdAt
        self.hostUserId = hostUserId
        self.inviteCode = inviteCode
        self.members = members
        self.postsByDate = postsByDate
    }
}

extension HCGroupDTO {
    public func toModel() -> HCGroup? {
        let formatter = ISO8601DateFormatter()
                
        guard
            let groupId = groupId,
            let groupName = groupName,
            let createdAtStr = createdAt,
            let createdAt = formatter.date(from: createdAtStr),
            let hostUserId = hostUserId,
            let inviteCode = inviteCode
        else {
            return nil
        }
        
        let memberDict = members ?? [:]
        
        
        var postsByDate: [String: [Post]] = [:]
        postsByDate = postsByDate.merging(
            self.postsByDate?.compactMapValues { dict in
                dict.compactMap { $0.value.toModel() }
            } ?? [:],
            uniquingKeysWith: { $1 }
        )
        
        return HCGroup(
            groupId: groupId,
            groupName: groupName,
            createdAt: createdAt,
            hostUserId: hostUserId,
            inviteCode: inviteCode,
            members: memberDict,
            postsByDate: postsByDate
        )
    }
}

extension HCGroup {
    public func toDTO() -> HCGroupDTO {
        let formatter = ISO8601DateFormatter()
        let postsDTO: [String: [String: PostDTO]] = postsByDate.mapValues { postList in
            Dictionary(uniqueKeysWithValues: postList.map { ($0.postId, $0.toDTO()) })
        }
        
        return HCGroupDTO(
            groupId: groupId,
            groupName: groupName,
            createdAt: formatter.string(from: createdAt),
            hostUserId: hostUserId,
            inviteCode: inviteCode,
            members: members,
            postsByDate: postsDTO
        )
    }
}

