//
//  GroupRepositoryProtocol.swift
//  Domain
//
//  Created by 김동현 on 2/4/26.
//

import RxSwift
import Core
import UIKit

protocol GroupRepositoryProtocol {
    func createGroup(groupName: String) -> Observable<Result<(groupId: String, inviteCode: String), GroupError>>
    func joinGroup(inviteCode: String) -> Observable<Result<HCGroup, GroupError>>
    func updateUserGroupId(groupId: String) -> Observable<Result<Void, GroupError>>
    func updateGroup(path: String, post: Post) -> Observable<Result<Void, GroupError>>
    func fetchGroup(groupId: String) -> Observable<Result<HCGroup, GroupError>>
    func uploadImage(image: UIImage, path: String) -> Observable<URL?>
    func deleteImage(path: String) -> Observable<Bool>
    func observeValueStream<T: Decodable>(path: String, type: T.Type) -> Observable<T>
    func deleteValue(path: String) -> Observable<Bool>
    
    func addComment(path: String, value: Comment) -> Observable<Bool>
    func deleteComment(path: String) -> Observable<Bool>
}
