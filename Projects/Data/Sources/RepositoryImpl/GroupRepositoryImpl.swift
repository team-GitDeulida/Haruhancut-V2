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
    
    public init(firebaseAuthManager: FirebaseAuthManagerProtocol, firebaseStorageManager: FirebaseStorageManagerProtocol
    ) {
        self.firebaseAuthManager = firebaseAuthManager
        self.firebaseStorageManager = firebaseStorageManager
    }
    
    // Group
    public func createGroup(groupName: String) -> Observable<Result<(groupId: String, inviteCode: String), GroupError>> {
        return firebaseAuthManager.createGroup(groupName: groupName)
            .map { .success($0) }
            .catch { _ in .just(.failure(.createGroupError)) }
    }
    
    public func joinGroup(inviteCode: String) -> Observable<Result<HCGroup, GroupError>> {
        return firebaseAuthManager.joinGroup(inviteCode: inviteCode)
            .map { .success($0) }
            .catch { _ in .just(.failure(.joinGroupError)) }
    }
    
    public func updateGroup(path: String, post: Post) -> Observable<Result<Void, GroupError>> {
        return firebaseAuthManager.updateGroup(path: path, post: post.toDTO())
            .map { .success($0) }
            .catch { _ in .just(.failure(.updateGroupError)) }
    }
    
    public func updateUserGroupId(groupId: String) -> Observable<Result<Void, GroupError>> {
        return firebaseAuthManager.updateUserGroupId(groupId: groupId)
            .map { .success($0) }
            .catch { _ in .just(.failure(.updateUserGroupIdError)) }
    }
    
    public func fetchGroup(groupId: String) -> Observable<Result<HCGroup, GroupError>> {
        return firebaseAuthManager.fetchGroup(groupId: groupId)
            .map { .success($0) }
            .catch { _ in .just(.failure(.fetchGroupError)) }
    }
    
    
    // Image
    public func uploadImage(image: UIImage, path: String) -> Observable<Result<URL, GroupError>> {
        return firebaseStorageManager.uploadImage(image: image, path: path)
            .map { .success($0) }
            .catch { _ in .just(.failure(.fetchImageError)) }
    }
    
    public func deleteImage(path: String) -> Observable<Result<Void, GroupError>> {
        return firebaseStorageManager.deleteImage(path: path)
            .map { .success($0) }
            .catch { _ in .just(.failure(.deleteImageError)) }
    }
    
    // Comment
    public func addComment(path: String, value: Comment) -> Observable<Result<Void, GroupError>> {
        return firebaseAuthManager.addComment(path: path, value: value.toDTO())
            .map { .success($0) }
            .catch { _ in .just(.failure(.addCommentError)) }
    }
    
    public func deleteComment(path: String) -> Observable<Result<Void, GroupError>> {
        return firebaseAuthManager.deleteValue(path: path)
            .map { .success($0) }
            .catch { _ in .just(.failure(.deleteCommentError)) }
    }
    
    
    // Other
    public func observeValueStream<T: Decodable>(path: String, type: T.Type) -> Observable<Result<T, GroupError>> {
        return firebaseAuthManager.observeValueStream(path: path, type: type)
            .map { .success($0) }
            .catch { _ in .just(.failure(.observeValueStreamError)) }
    }
    
    public func deleteValue(path: String) -> Observable<Result<Void, GroupError>> {
        return firebaseAuthManager.deleteValue(path: path)
            .map { .success($0) }
            .catch { _ in .just(.failure(.deleteValueError)) }
    }
}
