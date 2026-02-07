//
//  GroupRepositoryImpl.swift
//  Data
//
//  Created by 김동현 on 2/4/26.
//

import Foundation
import RxSwift
import FirebaseAuth
import FirebaseDatabase
import UIKit
import Core
import Domain

public final class GroupRepositoryImpl: GroupRepositoryProtocol {

    private let firebaseAuthManager: FirebaseAuthManagerProtocol
    private let firebaseStorageManager: FirebaseStorageManagerProtocol
    private let userSession: UserSessionType
    
    public init(firebaseAuthManager: FirebaseAuthManagerProtocol,
                firebaseStorageManager: FirebaseStorageManagerProtocol,
                userSession: UserSessionType
    ) {
        self.firebaseAuthManager = firebaseAuthManager
        self.firebaseStorageManager = firebaseStorageManager
        self.userSession = userSession
    }
    
    // Group
    public func createGroup(groupName: String) -> Single<(groupId: String, inviteCode: String)> {
        return firebaseAuthManager.createGroup(groupName: groupName)
    }
    
    public func joinGroup(inviteCode: String) -> Single<HCGroup> {
        return firebaseAuthManager.joinGroup(inviteCode: inviteCode)
    }
    
    public func updateGroup(path: String, post: Post) -> Single<Void> {
        return firebaseAuthManager.updateGroup(path: path, post: post.toDTO())
    }
    
    public func updateUserGroupId(groupId: String) -> Single<Void> {
        return firebaseAuthManager.updateUserGroupId(groupId: groupId)
            .do(onSuccess: { user in
                self.userSession.update(\.groupId, groupId)
            })
    }
    
    public func fetchGroup(groupId: String) -> Single<HCGroup> {
        return firebaseAuthManager.fetchGroup(groupId: groupId)
    }
    
    
    // Image
    public func uploadImage(image: UIImage, path: String) -> Single<URL> {
        return firebaseStorageManager.uploadImage(image: image, path: path)
    }
    
    public func deleteImage(path: String) -> Single<Void> {
        return firebaseStorageManager.deleteImage(path: path)
    }
    
    // Comment
    public func addComment(path: String, value: Comment) -> Single<Void> {
        return firebaseAuthManager.addComment(path: path, value: value.toDTO())
    }
    
    public func deleteComment(path: String) -> Single<Void> {
        return firebaseAuthManager.deleteValue(path: path)
    }
    
    
    // Other
    public func observeValueStream<T: Decodable>(path: String, type: T.Type) -> Observable<T> {
        return firebaseAuthManager.observeValueStream(path: path, type: type)
    }
    
    public func deleteValue(path: String) -> Single<Void> {
        return firebaseAuthManager.deleteValue(path: path)
    }
}
