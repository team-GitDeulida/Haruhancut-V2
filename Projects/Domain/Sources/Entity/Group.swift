//
//  Group.swift
//  Domain
//
//  Created by 김동현 on 1/20/26.
//

import Foundation

public struct HCGroup: Encodable {
    public let groupId: String
    public let groupName: String
    public let createdAt: Date
    public let hostUserId: String
    public let inviteCode: String
    public var members: [String: String] // [uid: joinedAt]
    public var postsByDate: [String: [Post]]
    
    public init(groupId: String, groupName: String, createdAt: Date, hostUserId: String, inviteCode: String, members: [String : String], postsByDate: [String : [Post]]) {
        self.groupId = groupId
        self.groupName = groupName
        self.createdAt = createdAt
        self.hostUserId = hostUserId
        self.inviteCode = inviteCode
        self.members = members
        self.postsByDate = postsByDate
    }
}


