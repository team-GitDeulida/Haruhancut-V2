//
//  Group.swift
//  Domain
//
//  Created by 김동현 on 1/20/26.
//

import Foundation
import Core

/// 그룹 멤버의 생일을 반복 계산할 달력 기준입니다.
public enum BirthdayCalendarMode:
    String,
    Codable,
    Equatable,
    CaseIterable
{
    case solar
    case lunar
}

/// 그룹 전체에 적용되는 생일 표시 설정입니다.
public struct GroupBirthdaySettings:
    Codable,
    Equatable
{
    public var isEnabled: Bool
    public var calendarMode:
        BirthdayCalendarMode

    public init(
        isEnabled: Bool,
        calendarMode:
            BirthdayCalendarMode
    ) {
        self.isEnabled = isEnabled
        self.calendarMode = calendarMode
    }

    /// 설정이 없는 기존 그룹에 적용할 기본값입니다.
    public static let defaultValue =
        GroupBirthdaySettings(
            isEnabled: true,
            calendarMode: .solar
        )
}

public struct HCGroup: Encodable, Decodable, CustomStringConvertible {
    public let groupId: String
    public let groupName: String
    public let createdAt: Date
    public let hostUserId: String
    public let inviteCode: String
    public var members: [String: String] // [uid: joinedAt]
    public var postsByDate: [String: [Post]]
    public var birthdaySettings:
        GroupBirthdaySettings?

    public var resolvedBirthdaySettings:
        GroupBirthdaySettings
    {
        birthdaySettings ?? .defaultValue
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
    
    public init(
        groupId: String,
        groupName: String,
        createdAt: Date,
        hostUserId: String,
        inviteCode: String,
        members: [String: String],
        postsByDate: [String: [Post]],
        birthdaySettings:
            GroupBirthdaySettings? = nil
    ) {
        self.groupId = groupId
        self.groupName = groupName
        self.createdAt = createdAt
        self.hostUserId = hostUserId
        self.inviteCode = inviteCode
        self.members = members
        self.postsByDate = postsByDate
        self.birthdaySettings =
            birthdaySettings
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
    public var birthdaySettings:
        GroupBirthdaySettings?

    public var resolvedBirthdaySettings:
        GroupBirthdaySettings
    {
        birthdaySettings ?? .defaultValue
    }

    public init(
        groupId: String,
        groupName: String,
        createdAt: Date,
        hostUserId: String,
        inviteCode: String,
        members: [String: String],
        postsByDate: [String: [Post]],
        birthdaySettings:
            GroupBirthdaySettings? = nil
    ) {
        self.groupId = groupId
        self.groupName = groupName
        self.createdAt = createdAt
        self.hostUserId = hostUserId
        self.inviteCode = inviteCode
        self.members = members
        self.postsByDate = postsByDate
        self.birthdaySettings =
            birthdaySettings
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
            postsByDate: postsByDate,
            birthdaySettings:
                birthdaySettings
        )
    }
}

extension SessionGroup {
    public func toEntity() -> HCGroup {
        return HCGroup(
            groupId: groupId,
            groupName: groupName,
            createdAt: createdAt,
            hostUserId: hostUserId,
            inviteCode: inviteCode,
            members: members,
            postsByDate: postsByDate,
            birthdaySettings:
                birthdaySettings
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

    var birthdaySettings:
        GroupBirthdaySettings
    {
        session?
            .resolvedBirthdaySettings
            ?? .defaultValue
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
