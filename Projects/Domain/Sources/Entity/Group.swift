//
//  Group.swift
//  Domain
//
//  Created by 김동현 on 1/20/26.
//

import Foundation
import Core

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

// MARK: - Group Session
public typealias GroupSession = SessionContext<SessionGroup>
public struct SessionGroup: Codable, Equatable, CustomStringConvertible {

    public var groupId: String
    public var groupName: String
    public var createdAt: Date
    public var hostUserId: String
    public var inviteCode: String
    public var members: [String: String]
    public var postsByDate: [String: [Post]]

    public init(
        groupId: String,
        groupName: String,
        createdAt: Date,
        hostUserId: String,
        inviteCode: String,
        members: [String: String],
        postsByDate: [String: [Post]]
    ) {
        self.groupId = groupId
        self.groupName = groupName
        self.createdAt = createdAt
        self.hostUserId = hostUserId
        self.inviteCode = inviteCode
        self.members = members
        self.postsByDate = postsByDate
    }

    public var description: String {
        """
        SessionGroup(
        - groupId: \(groupId)
        - groupName: \(groupName)
        - members: \(members.count)
        - posts count: \(postsByDate.values.flatMap { $0 }.count)
        )
        """
    }
}

extension HCGroup {
    public func toSession() -> SessionGroup {
        SessionGroup(
            groupId: groupId,
            groupName: groupName,
            createdAt: createdAt,
            hostUserId: hostUserId,
            inviteCode: inviteCode,
            members: members,
            postsByDate: postsByDate
        )
    }
}

extension SessionGroup {
    public func toEntity() -> HCGroup {
        HCGroup(
            groupId: groupId,
            groupName: groupName,
            createdAt: createdAt,
            hostUserId: hostUserId,
            inviteCode: inviteCode,
            members: members,
            postsByDate: postsByDate
        )
    }
}

public extension SessionContext where Model == SessionGroup {

    var groupId: String? { session?.groupId }
    var groupName: String? { session?.groupName }
    var createdAt: Date? { session?.createdAt }
    var hostUserId: String? { session?.hostUserId }
    var inviteCode: String? { session?.inviteCode }

    var members: [String: String] {
        session?.members ?? [:]
    }

    var postsByDate: [String: [Post]] {
        session?.postsByDate ?? [:]
    }

    var hasGroup: Bool {
        session != nil
    }

    var totalPostCount: Int {
        session?.postsByDate.values.flatMap { $0 }.count ?? 0
    }

    /// Entity 변환
    var entity: HCGroup? {
        session?.toEntity()
    }
}
