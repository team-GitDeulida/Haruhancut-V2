//
//  GroupRepositoryProtocol.swift
//  Domain
//
//  Created by 김동현 on 2/4/26.
//

import RxSwift
import Core
import UIKit

public protocol GroupRepositoryProtocol {
    // Group
    func createGroup(groupName: String) -> Observable<Result<(groupId: String, inviteCode: String), GroupError>>
    func joinGroup(inviteCode: String) -> Observable<Result<HCGroup, GroupError>>
    func updateGroup(path: String, post: Post) -> Observable<Result<Void, GroupError>>
    func updateUserGroupId(groupId: String) -> Observable<Result<Void, GroupError>>
    func fetchGroup(groupId: String) -> Observable<Result<HCGroup, GroupError>>
    
    // Image
    func uploadImage(image: UIImage, path: String) -> Observable<Result<URL, GroupError>>
    func deleteImage(path: String) -> Observable<Result<Void, GroupError>>
    
    // Comment
    func addComment(path: String, value: Comment) -> Observable<Result<Void, GroupError>>
    func deleteComment(path: String) -> Observable<Result<Void, GroupError>>
    
    // Other
    func observeValueStream<T: Decodable>(path: String, type: T.Type) -> Observable<Result<T, GroupError>>
    func deleteValue(path: String) -> Observable<Result<Void, GroupError>>
}
