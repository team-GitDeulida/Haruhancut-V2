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
    func createGroup(groupName: String) -> Single<(groupId: String, inviteCode: String)>
    func joinGroup(inviteCode: String) -> Single<HCGroup>
    func updateGroup(path: String, post: Post) -> Single<Void>
    func updateUserGroupId(groupId: String) -> Single<Void>
    func fetchGroup(groupId: String) -> Single<HCGroup>
    
    // Image
    func uploadImage(image: UIImage, path: String) -> Single<URL>
    func deleteImage(path: String) -> Single<Void>
    
    // Comment
    func addComment(path: String, value: Comment) -> Single<Void>
    func deleteComment(path: String) -> Single<Void>
    
    // Other
    func observeValueStream<T: Decodable>(path: String, type: T.Type) -> Observable<T>
    func deleteValue(path: String) -> Single<Void>
}
