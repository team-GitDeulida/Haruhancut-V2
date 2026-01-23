////
////  FirebaseAuthManager.swift
////  Core
////
////  Created by 김동현 on 1/13/26.
////
//
//import FirebaseAuth
//import FirebaseDatabase
//import RxSwift
//import Core
//import Domain
//
////enum ProviderID: String {
////    case kakao
////    case apple
////    var authProviderID: AuthProviderID {
////        switch self {
////        case .kakao: return .custom("oidc.kakao")
////        case .apple: return .apple
////        }
////    }
////}
//
//enum ProviderID: String {
//    case kakao
//    case apple
//    var authProviderID: AuthProviderID {
//        switch self {
//        case .kakao: return AuthProviderID.custom("oidc.kakao")
//        case .apple: return AuthProviderID.apple // Self(rawValue: "apple.com")
//        }
//    }
//}
//
///*
//extension ProviderID {
//    func makeCredential(
//        idToken: String,
//        rawNonce: String?
//    ) -> AuthCredential {
//
//        switch self {
//        case .apple:
//            guard let rawNonce else {
//                fatalError("Apple login requires rawNonce")
//            }
//
//            return OAuthProvider.credential(
//                providerID: .apple,
//                idToken: idToken,
//                rawNonce: rawNonce,
//                accessToken: nil
//            )
//
//        case .kakao:
//            return OAuthProvider.credential(
//                providerID: .custom("oidc.kakao"),
//                idToken: idToken,
//                rawNonce: rawNonce ?? "",
//                accessToken: nil
//            )
//        }
//    }
//}
// */
//
//extension ProviderID {
//    func makeCredential(
//        idToken: String,
//        rawNonce: String?
//    ) -> AuthCredential {
//
//        switch self {
//        case .apple:
//
//
//            return OAuthProvider.credential(
//                providerID: .apple,
//                idToken: idToken,
//                rawNonce: rawNonce ?? ""
//            )
//
//        case .kakao:
//            return OAuthProvider.credential(
//                providerID: .custom("oidc.kakao"),
//                idToken: idToken,
//                rawNonce: rawNonce ?? ""
//            )
//        }
//    }
//}
//
//
//public protocol FirebaseAuthManagerProtocol {
//    // 제네릭
//    func setValue<T: Encodable>(path: String, value: T) -> Observable<Bool>      // create
//    func readValue<T: Decodable>(path: String, type: T.Type) -> Observable<T>    // read
//    func updateValue<T: Encodable>(path: String, value: T) -> Observable<Bool>   // update
//    func deleteValue(path: String) -> Observable<Bool>                           // dellete
//    
//    
//    // 유저관련
//    func authenticateUser(prividerID: String, idToken: String, rawNonce: String?) -> Observable<Result<Void, LoginError>>
//    func registerUserToRealtimeDatabase(user: Domain.User) -> Observable<Result<Domain.User, LoginError>>
//    func fetchMyInfo() -> Observable<Domain.User?> // 원래 fetchUserInfo() 네이밍에서 변경
//    func fetchUser(uid: String) -> Observable<Domain.User?>
//    func updateUser(user: Domain.User) -> Observable<Result<Domain.User, LoginError>>
//    func deleteUser(uid: String) -> Observable<Bool>
//    
//    
//    // 그룹관련
//    func createGroup(groupName: String) -> Observable<Result<(groupId: String, inviteCode: String), GroupError>>
//    func updateUserGroupId(groupId: String) -> Observable<Result<Void, GroupError>>
//    func fetchGroup(groupId: String) -> Observable<Result<HCGroup, GroupError>>
//    func joinGroup(inviteCode: String) -> Observable<Result<HCGroup, GroupError>>
//    func updateGroup(path: String, post: PostDTO) -> Observable<Bool>
//    
//    // 댓글관련
//    func addComment(path: String, value: CommentDTO) -> Observable<Bool>
//    func deleteComment(path: String) -> Observable<Bool>
//    
//    // 스냅샷관련
//    func observeValueStream<T: Decodable>(path: String, type: T.Type) -> Observable<T>
//}
//
//public final class FirebaseAuthManager {
//    
//    private var databaseRef: DatabaseReference {
//        Database.database(url: Constants.Firebase.realtimeURL).reference()
//    }
//    
//    public init() {
//        print("🔥 Auth called from bundle:",
//              Bundle.main.bundleIdentifier ?? "nil")
//    }
//}
//
//// MARK: - CRUD
//extension FirebaseAuthManager: FirebaseAuthManagerProtocol {
//    /// Create or Overwrite
//    /// - Parameters:
//    ///   - path: 경로
//    ///   - value: 값
//    /// - Returns: Observable<Bool>
//    public func setValue<T: Encodable>(path: String, value: T) -> Observable<Bool> {
//        return Observable.create { observer in
//            do {
//                let data = try JSONEncoder().encode(value)
//                let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
//                
//                self.databaseRef.child(path).setValue(dict) { error, _ in
//                    if let error = error {
//                        print("🔥 setValue 실패: \(error.localizedDescription)")
//                        observer.onError(error)
//                    } else {
//                        observer.onNext(true)
//                    }
//                    observer.onCompleted()
//                }
//            } catch {
//                observer.onError(error)
//            }
//            return Disposables.create()
//        }
//    }
//    
//    /// Read - 1회 요청
//    /// - Parameters:
//    ///   - path: 경로
//    ///   - type: 값
//    /// - Returns: Observable<T>
//    public func readValue<T: Decodable>(path: String, type: T.Type) -> Observable<T> {
//        return Observable.create { observer in
//            self.databaseRef.child(path).observeSingleEvent(of: .value) { snapshot in
//                guard let value = snapshot.value else {
//                    observer.onError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "값이 존재하지 않음"]))
//                    return
//                }
//                
//                do {
//                    guard JSONSerialization.isValidJSONObject(value) else {
//                        throw NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "유효하지 않은 JSON 객체"])
//                    }
//                    
//                    let data = try JSONSerialization.data(withJSONObject: value, options: [])
//                    let decoded = try JSONDecoder().decode(T.self, from: data)
//                    observer.onNext(decoded)
//                } catch {
//                    observer.onError(error)
//                }
//                observer.onCompleted()
//            }
//            return Disposables.create()
//        }
//    }
//
//    
//    /// Firebase Realtime Database의 해당 경로에 있는 데이터를 일부 필드만 병합 업데이트합니다.
//    /// - 기존 데이터는 유지하면서, 전달한 값의 필드만 갱신됩니다.
//    ///
//    /// 예: 댓글에 'text'만 수정할 때 유용
//    ///
//    /// - Parameters:
//    ///   - path: 업데이트할 Firebase 경로
//    ///   - value: 업데이트할 일부 필드를 가진 값 (Encodable → Dictionary로 변환됨)
//    /// - Returns: 업데이트 성공 여부를 방출하는 Observable<Bool>
//    public func updateValue<T: Encodable>(path: String, value: T) -> Observable<Bool> {
//        return Observable.create { observer in
//            guard let dict = value.toDictionary() else {
//                observer.onNext(false)
//                observer.onCompleted()
//                return Disposables.create()
//            }
//            
//            self.databaseRef.child(path).updateChildValues(dict) { error, _ in
//                if let error = error {
//                    print("❌ updateValue 실패: \(error.localizedDescription)")
//                    observer.onNext(false)
//                } else {
//                    // print("✅ updateValue 성공: \(path)")
//                    observer.onNext(true)
//                }
//                observer.onCompleted()
//            }
//            
//            return Disposables.create()
//        }
//    }
//
//    /// Delete
//    /// - Parameter path: 삭제할 Firebase realtime 데이터 경로
//    /// - Returns: 삭제 성공 여부 방출하는 Observable<Bool>
//    public func deleteValue(path: String) -> Observable<Bool> {
//        return Observable.create { observer in
//            self.databaseRef.child(path).removeValue { error, _ in
//                if let error = error {
//                    print("❌ deleteValue 실패: \(error.localizedDescription)")
//                    observer.onNext(false)
//                } else {
//                    print("✅ deleteValue 성공: \(path)")
//                    observer.onNext(true)
//                }
//                observer.onCompleted()
//            }
//            return Disposables.create()
//        }
//    }
//}
//
//import FirebaseCore
//import FirebaseMessaging
//
//// MARK: - 유저 관련
//extension FirebaseAuthManager {
//    
//    /// Firebase Auth에 소셜 로그인으로 인증 요청
//    /// - Parameters:
//    ///   - prividerID: .kakao, .apple
//    ///   - idToken: kakaoToken, appleToken
//    /// - Returns: Result<Void, LoginError>
//    public func authenticateUser(prividerID: String, idToken: String, rawNonce: String?) -> Observable<Result<Void, LoginError>> {
//        
//        // 🔴 1단계: FirebaseApp 존재 여부 확인
//        print("테스트")
//            guard let app = FirebaseApp.app() else {
//                print("❌ FirebaseApp.app() == nil (configure 안 됨)")
//                return .just(.failure(.authError))
//            }
//        
//        guard let provider = ProviderID(rawValue: prividerID) else {
//            print("이거")
//            return Observable.just(.failure(LoginError.signUpError))
//        }
//        
////        let credential = OAuthProvider.credential(
////            providerID: provider.authProviderID,
////            idToken: idToken,
////            rawNonce: rawNonce ?? "")
//        
//        let credential = provider.makeCredential(
//            idToken: idToken,
//            rawNonce: rawNonce
//        )
//        
//        return Observable.create { observer in
//            print("앱 디버깅: \(app)")
//
//            Auth.auth().signIn(with: credential) { _, error in
//                
//            //let auth = Auth.auth(app: app)
//            //auth.signIn(with: credential) { _, error in
//                if let error = error {
//                    print("❌ Firebase 인증 실패: \(error.localizedDescription)")
//                    observer.onNext(.failure(LoginError.signUpError))
//                } else {
//                    observer.onNext(.success(()))
//                }
//                observer.onCompleted()
//            }
//            return Disposables.create()
//        }
//    }
//    
//    /// Firebase Realtime Database에 유저 정보를 저장하고, 저장된 User를 반환 - create
//    /// - Parameter user: 저장할 User 객체
//    /// - Returns: Result<User, LoginError>
//    public func registerUserToRealtimeDatabase(user: Domain.User) -> Observable<Result<Domain.User, LoginError>> {
//        guard let firebaseUID = Auth.auth().currentUser?.uid else {
//            return Observable.just(.failure(.authError))
//        }
//
//        var userEntity = user
//        userEntity.uid = firebaseUID
//        let userDto = userEntity.toDTO()
//        let path = "users/\(firebaseUID)"
//
//        return setValue(path: path, value: userDto)
//            .map { success in
//                return success ? .success(userEntity) : .failure(.signUpError)
//            }
//            .catch { error in
//                print("❌ setValue 중 에러 발생: \(error.localizedDescription)")
//                return Observable.just(.failure(.signUpError))
//            }
//    }
//    
//    /// 나의 유저정보 불러오기 - read
//    /// - Returns: Observable<User?>
//    public func fetchMyInfo() -> Observable<Domain.User?> {
//        guard let uid = Auth.auth().currentUser?.uid else {
//            print("🔸 로그인된 유저 없음")
//            return Observable.just(nil)
//        }
//        
//        let path = "users/\(uid)"
//            
//            return readValue(path: path, type: UserDTO.self)
//                .map { dto in
//                    return dto.toModel()
//                }
//                .catch { error in
//                    print("❌ 유저 정보 디코딩 실패 - nil반환: \(error.localizedDescription)")
//                    return Observable.just(nil)
//                }
//    }
//    
//    /// Uid기반 유저 정보 가져오기 - read
//    /// - Parameter uid: uid
//    /// - Returns: Observable<User?>
//    public func fetchUser(uid: String) -> Observable<Domain.User?> {
//        let path = "users/\(uid)"
//            
//            return readValue(path: path, type: UserDTO.self)
//                .map { dto in
//                    return dto.toModel()
//                }
//                .catch { error in
//                    print("❌ 유저 정보 디코딩 실패: \(error.localizedDescription)")
//                    return Observable.just(nil)
//                }
//    }
//    
//    /// 유저 업데이트 - update
//    /// - Parameter user: user구조체
//    /// - Returns: Observable<Result<User, LoginError>>
//    public func updateUser(user: Domain.User) -> Observable<Result<Domain.User, LoginError>> {
//        let path = "users/\(user.uid)"
//        let dto = user.toDTO()
//        
//        return updateValue(path: path, value: dto)
//            .map { success -> Result<Domain.User, LoginError> in
//                if success {
//                    return .success(user)
//                } else {
//                    return .failure(.updateUserError)
//                }
//            }
//    }
//    
//    /// 유저 삭제 - delete
//    /// - Parameter uid: Uid
//    /// - Returns: 삭제유무
//    public func deleteUser(uid: String) -> Observable<Bool> {
//        // 1. 유저 정보 읽기(groudId 확보용)
//        return fetchUser(uid: uid)
//            .flatMap { (user: Domain.User!) -> Observable<Bool> in
//                guard let groudId = user.groupId else {
//                    // 그룹이 없으면 곧바로 성공
//                    return .just(true)
//                }
//                // 2. 그룹 멤버 경로에서 삭제
//                let memberPath = "groups/\(groudId)/members/\(uid)"
//                return self.deleteValue(path: memberPath)
//            }
//            .flatMap { (groupRemovalSuccess: Bool) -> Observable<Bool> in
//                guard groupRemovalSuccess else {
//                    // 그룹에서 제거 실패
//                    return .just(false)
//                }
//                // 3 users/{uid} 데이터 삭제
//                let userPath = "users/\(uid)"
//                return self.deleteValue(path: userPath)
//            }
//            .flatMap { (userRemoved: Bool) -> Observable<Bool> in
//                guard userRemoved else {
//                    // 유저 데이터 삭제 실패
//                    return .just(false)
//                }
//                // 4. Firebase Auth 계정 삭제
//                guard let currentUser = Auth.auth().currentUser,
//                      currentUser.uid == uid else {
//                    return .just(false)
//                }
//                return Observable<Bool>.create { observer in
//                    currentUser.delete { error in
//                        observer.onNext(error == nil)
//                        observer.onCompleted()
//                    }
//                    return Disposables.create()
//                }
//            }
//    }
//}
//
//// MARK: - 그룹 관련
//extension FirebaseAuthManager {
//    /// 초대 코드 생성기
//    private func generateInviteCode(length: Int = 6) -> String {
//        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
//        return String((0..<length).compactMap { _ in characters.randomElement() })
//    }
//    
//    /// 그룹 만들기
//    /// - Parameter groupName: 그룹 이름
//    /// - Returns: Observable<Result<(groupId: String, inviteCode: String), GroupError>>
//    public func createGroup(groupName: String) -> Observable<Result<(groupId: String, inviteCode: String), GroupError>> {
//        let newGroupRef = self.databaseRef.child("groups").childByAutoId()
//        
//        guard let currentUserId = Auth.auth().currentUser?.uid else {
//            print("❌ 현재 로그인된 유저 없음")
//            return Observable.just(.failure(.makeHostError))
//        }
//        
//        let inviteCode = self.generateInviteCode()
//        let joinedAt = Date().toISO8601String()
//        
//        let groupData = HCGroup(
//            groupId: newGroupRef.key ?? "",
//            groupName: groupName,
//            createdAt: Date(),
//            hostUserId: currentUserId,
//            inviteCode: inviteCode,
//            members: [currentUserId: joinedAt],
//            postsByDate: [:]
//        )
//        
//        return setValue(path: "groups/\(newGroupRef.key ?? "")", value: groupData.toDTO())
//            .map { success -> Result<(groupId: String, inviteCode: String), GroupError> in
//                if success {
//                    print("✅ 그룹 생성 성공! ID: \(newGroupRef.key ?? "")")
//                    return .success((groupId: newGroupRef.key ?? "", inviteCode: inviteCode))
//                } else {
//                    print("❌ 그룹 생성 실패")
//                    return .failure(.makeHostError)
//                }
//            }
//    }
//    
//    /// 그룹 Create후 유저속성에 추가
//    /// - Parameter groupId: 그룹 Id
//    /// - Returns: Observable<Result<Void, GroupError>>
//    public func updateUserGroupId(groupId: String) -> Observable<Result<Void, GroupError>> {
//        
//        /// 현재 유저의 UID를 구한다
//        guard let currentUserId = Auth.auth().currentUser?.uid else {
//            print("❌ 현재 로그인된 유저 없음")
//            return Observable.just(.failure(.makeHostError))
//        }
//            
//        /// UID 기반으로 저장할 위치경로를 정한다
//        let path = "users/\(currentUserId)"
//        let update = ["groupId": groupId]
//        
//        return updateValue(path: path, value: update)
//            .map { success -> Result<Void, GroupError> in
//                if success {
//                    return .success(())
//                } else {
//                    return .failure(.makeHostError)
//                }
//        }
//    }
//    
//    /// 그룹 Read
//    /// - Parameter groupId: 그룹 ID
//    /// - Returns: Observable<Result<HCGroup, GroupError>>
//    public func fetchGroup(groupId: String) -> Observable<Result<HCGroup, GroupError>> {
//        return readValue(path: "groups/\(groupId)", type: HCGroupDTO.self)
//            .map { dto in
//                if let group = dto.toModel() {
//                    return .success(group)
//                } else {
//                    return .failure(.fetchGroupError)
//                }
//            }
//            .catch { error in
//                print("❌ 그룹 정보 가져오기 실패: \(error.localizedDescription)")
//                return Observable.just(.failure(.fetchGroupError))
//            }
//    }
//    
//    
//    /// 그룸 참가
//    /// - Parameter inviteCode: 초대 코드
//    /// - Returns: Observable<Result<HCGroup, GroupError>>
//    public func joinGroup(inviteCode: String) -> Observable<Result<HCGroup, GroupError>> {
//        return readValue(path: "groups", type: [String: HCGroupDTO].self)
//            .flatMap { groupDict -> Observable<Result<HCGroup, GroupError>> in
//                let groups = groupDict.compactMapValues { $0.toModel() }
//                
//                guard let matched = groups.values.first(where: { $0.inviteCode == inviteCode }) else {
//                    print("❌ 초대코드로 일치하는 그룹 없음")
//                    return Observable.just(.failure(.fetchGroupError))
//                }
//                
//                guard let currentUID = Auth.auth().currentUser?.uid else {
//                    return Observable.just(.failure(.makeHostError))
//                }
//                
//                let groupId = matched.groupId
//                let membersPath = "groups/\(groupId)/members"
//                let groupPath = "groups/\(groupId)"
//                
//                // ✅ [uid: joinedAt] 형태로 불러오기
//                return self.readValue(path: membersPath, type: [String: String].self)
//                    .catchAndReturn([:]) // 멤버가 없을 수도 있으므로 안전하게
//                    .flatMap { existingMembers in
//                        var newMembers = existingMembers
//                        let joinedAt = Date().toISO8601String()
//                        
//                        newMembers[currentUID] = joinedAt
//                        
//                        // ✅ members 업데이트
//                        let membersDict: [String: Any] = ["members": newMembers]
//                        
//                        return Observable.create { observer in
//                            self.databaseRef.child(groupPath).updateChildValues(membersDict) { error, _ in
//                                if let error = error {
//                                    print("❌ members 업데이트 실패: \(error.localizedDescription)")
//                                    observer.onNext(false)
//                                } else {
//                                    print("✅ members 업데이트 성공")
//                                    observer.onNext(true)
//                                }
//                                observer.onCompleted()
//                            }
//                            return Disposables.create()
//                        }
//                    }
//                    .flatMap { success in
//                        if success {
//                            return self.updateUserGroupId(groupId: groupId)
//                                .map { updateResult in
//                                    switch updateResult {
//                                    case .success:
//                                        return Result<HCGroup, GroupError>.success(matched)
//                                    case .failure:
//                                        return Result<HCGroup, GroupError>.failure(.makeHostError)
//                                    }
//                                }
//                        } else {
//                            return .just(.failure(.makeHostError))
//                        }
//                    }
//            }
//            .catch { error in
//                print("❌ 그룹 조회 실패: \(error)")
//                return Observable.just(.failure(.fetchGroupError))
//            }
//    }
//    
//    
//    
//    /// 그룹 업데이트
//    /// - Parameters:
//    ///   - path: 업데이트할 경로
//    ///   - post: 올릴 포스트
//    /// - Returns: 업데이트 결과
//    public func updateGroup(path: String, post: PostDTO) -> Observable<Bool> {
//        return updateValue(path: path, value: post)
//    }
//}
//
//// MARK: - 댓글 관련
//extension FirebaseAuthManager {
//    public func addComment(path: String, value: CommentDTO) -> Observable<Bool> {
//        return setValue(path: path, value: value)
//    }
//    public func deleteComment(path: String) -> Observable<Bool> {
//        return deleteValue(path: path)
//    }
//}
//
//// MARK: - 실시간 스냅샷 관련
//extension FirebaseAuthManager {
//    /// 실시간 스냅샷 감지
//    /// Firebase Realtime Database에서 특정 경로(path)의 데이터를 **실시간으로 관찰**합니다.
//    /// 해당 경로의 데이터가 변경될 때마다 최신 데이터를 가져와 스트림으로 방출합니다.
//    /// - Parameters:
//    ///   - path: Firebase Realtime Database 내에서 데이터를 관찰할 경로 문자열
//    ///   - type: 디코딩할 모델 타입 (`Decodable`을 준수하는 타입)
//    /// - Returns: 실시간으로 감지된 데이터를 방출하는 `Observable<T>`
//    public func observeValueStream<T: Decodable>(path: String, type: T.Type) -> Observable<T> {
//        return Observable.create { observer in
//            let ref = self.databaseRef.child(path)
//            let handle = ref.observe(.value) { snapshot in
//                
//                guard let value = snapshot.value else {
//                    print("📛 실시간 observe: value 없음")
//                    observer.onError(NSError(domain: "firebase", code: -1, userInfo: [NSLocalizedDescriptionKey: "값이 없음"]))
//                    return
//                }
//                
//                // 🔴 안전성: 직렬화 가능한 타입인지 검사
//               guard JSONSerialization.isValidJSONObject(value) else {
//                   observer.onError(NSError(domain: "firebase", code: -2, userInfo: [NSLocalizedDescriptionKey: "직렬화 불가능한 타입"]))
//                   return
//               }
//                
//                do {
//                    let data = try JSONSerialization.data(withJSONObject: value, options: [])
//                    let decoded = try JSONDecoder().decode(T.self, from: data)
//                    observer.onNext(decoded)
//                } catch {
//                    print("❌ observeValueStream 디코딩 실패: \(error.localizedDescription)")
//                    observer.onError(error)
//                }
//            }
//
//            return Disposables.create {
//                ref.removeObserver(withHandle: handle)
//            }
//        }
//    }
//}

//
//  FirebaseAuthManager.swift
//  Haruhancut
//
//  Created by 김동현 on 6/17/25.
//
import FirebaseAuth
import FirebaseDatabase
import RxSwift
import RxCocoa
import Core
import Domain

public enum ProviderID: String {
    case kakao
    case apple
    var authProviderID: AuthProviderID {
        switch self {
        case .kakao: return .custom("oidc.kakao")
        case .apple: return .apple
        }
    }
}

public protocol FirebaseAuthManagerProtocol {
    // 제네릭
    func setValue<T: Encodable>(path: String, value: T) -> Observable<Bool>      // create
    func readValue<T: Decodable>(path: String, type: T.Type) -> Observable<T>    // read
    func updateValue<T: Encodable>(path: String, value: T) -> Observable<Bool>   // update
    func deleteValue(path: String) -> Observable<Bool>                           // dellete
    
    
    // 유저관련
    func authenticateUser(prividerID: String, idToken: String, rawNonce: String?) -> Observable<Result<Void, LoginError>>
    func registerUserToRealtimeDatabase(user: Domain.User) -> Observable<Result<Domain.User, LoginError>>
    func fetchMyInfo() -> Observable<Domain.User?> // 원래 fetchUserInfo() 네이밍에서 변경
    func fetchUser(uid: String) -> Observable<Domain.User?>
    func updateUser(user: Domain.User) -> Observable<Result<Domain.User, LoginError>>
    func deleteUser(uid: String) -> Observable<Bool>
    
    
    // 그룹관련
    func createGroup(groupName: String) -> Observable<Result<(groupId: String, inviteCode: String), GroupError>>
    func updateUserGroupId(groupId: String) -> Observable<Result<Void, GroupError>>
    func fetchGroup(groupId: String) -> Observable<Result<HCGroup, GroupError>>
    func joinGroup(inviteCode: String) -> Observable<Result<HCGroup, GroupError>>
    func updateGroup(path: String, post: PostDTO) -> Observable<Bool>
    
    // 댓글관련
    func addComment(path: String, value: CommentDTO) -> Observable<Bool>
    func deleteComment(path: String) -> Observable<Bool>
    
    // 스냅샷관련
    func observeValueStream<T: Decodable>(path: String, type: T.Type) -> Observable<T>
}

public final class FirebaseAuthManager: FirebaseAuthManagerProtocol {
   
    public init() {}
    private var databaseRef: DatabaseReference {
        Database.database(url: Constants.Firebase.realtimeURL).reference()
    }
}

// MARK: - Realtime Database 제네릭 함수
extension FirebaseAuthManager {
    
    /// Create or Overwrite
    /// - Parameters:
    ///   - path: 경로
    ///   - value: 값
    /// - Returns: Observable<Bool>
    public func setValue<T: Encodable>(path: String, value: T) -> Observable<Bool> {
        return Observable.create { observer in
            do {
                let data = try JSONEncoder().encode(value)
                let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                
                self.databaseRef.child(path).setValue(dict) { error, _ in
                    if let error = error {
                        print("🔥 setValue 실패: \(error.localizedDescription)")
                        observer.onError(error)
                    } else {
                        observer.onNext(true)
                    }
                    observer.onCompleted()
                }
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }
    
    /// Read - 1회 요청
    /// - Parameters:
    ///   - path: 경로
    ///   - type: 값
    /// - Returns: Observable<T>
    public func readValue<T: Decodable>(path: String, type: T.Type) -> Observable<T> {
        return Observable.create { observer in
            self.databaseRef.child(path).observeSingleEvent(of: .value) { snapshot in
                guard let value = snapshot.value else {
                    observer.onError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "값이 존재하지 않음"]))
                    return
                }
                
                do {
                    guard JSONSerialization.isValidJSONObject(value) else {
                        throw NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "유효하지 않은 JSON 객체"])
                    }
                    
                    let data = try JSONSerialization.data(withJSONObject: value, options: [])
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    observer.onNext(decoded)
                } catch {
                    observer.onError(error)
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }

    
    /// Firebase Realtime Database의 해당 경로에 있는 데이터를 일부 필드만 병합 업데이트합니다.
    /// - 기존 데이터는 유지하면서, 전달한 값의 필드만 갱신됩니다.
    ///
    /// 예: 댓글에 'text'만 수정할 때 유용
    ///
    /// - Parameters:
    ///   - path: 업데이트할 Firebase 경로
    ///   - value: 업데이트할 일부 필드를 가진 값 (Encodable → Dictionary로 변환됨)
    /// - Returns: 업데이트 성공 여부를 방출하는 Observable<Bool>
    public func updateValue<T: Encodable>(path: String, value: T) -> Observable<Bool> {
        return Observable.create { observer in
            guard let dict = value.toDictionary() else {
                observer.onNext(false)
                observer.onCompleted()
                return Disposables.create()
            }
            
            self.databaseRef.child(path).updateChildValues(dict) { error, _ in
                if let error = error {
                    print("❌ updateValue 실패: \(error.localizedDescription)")
                    observer.onNext(false)
                } else {
                    // print("✅ updateValue 성공: \(path)")
                    observer.onNext(true)
                }
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }

    /// Delete
    /// - Parameter path: 삭제할 Firebase realtime 데이터 경로
    /// - Returns: 삭제 성공 여부 방출하는 Observable<Bool>
    public func deleteValue(path: String) -> Observable<Bool> {
        return Observable.create { observer in
            self.databaseRef.child(path).removeValue { error, _ in
                if let error = error {
                    print("❌ deleteValue 실패: \(error.localizedDescription)")
                    observer.onNext(false)
                } else {
                    print("✅ deleteValue 성공: \(path)")
                    observer.onNext(true)
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
}

// MARK: - 유저 관련
extension FirebaseAuthManager {
    
    /// Firebase Auth에 소셜 로그인으로 인증 요청
    /// - Parameters:
    ///   - prividerID: .kakao, .apple
    ///   - idToken: kakaoToken, appleToken
    /// - Returns: Result<Void, LoginError>
    public func authenticateUser(prividerID: String, idToken: String, rawNonce: String?) -> Observable<Result<Void, LoginError>> {
        guard let provider = ProviderID(rawValue: prividerID) else {
            return Observable.just(.failure(LoginError.signUpError))
        }
        
        let credential = OAuthProvider.credential(
            providerID: provider.authProviderID,
            idToken: idToken,
            rawNonce: rawNonce ?? "")
        
        return Observable.create { observer in
            Auth.auth().signIn(with: credential) { _, error in
                
                if let error = error {
                    print("❌ Firebase 인증 실패: \(error.localizedDescription)")
                    observer.onNext(.failure(LoginError.signUpError))
                } else {
                    observer.onNext(.success(()))
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    
    /// Firebase Realtime Database에 유저 정보를 저장하고, 저장된 User를 반환 - create
    /// - Parameter user: 저장할 User 객체
    /// - Returns: Result<User, LoginError>
    public func registerUserToRealtimeDatabase(user: Domain.User) -> Observable<Result<Domain.User, LoginError>> {
        guard let firebaseUID = Auth.auth().currentUser?.uid else {
            return Observable.just(.failure(.authError))
        }

        var userEntity = user
        userEntity.uid = firebaseUID
        let userDto = userEntity.toDTO()
        let path = "users/\(firebaseUID)"

        return setValue(path: path, value: userDto)
            .map { success in
                return success ? .success(userEntity) : .failure(.signUpError)
            }
            .catch { error in
                print("❌ setValue 중 에러 발생: \(error.localizedDescription)")
                return Observable.just(.failure(.signUpError))
            }
    }
    
    /// 나의 유저정보 불러오기 - read
    /// - Returns: Observable<User?>
    public func fetchMyInfo() -> Observable<Domain.User?> {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("🔸 로그인된 유저 없음")
            return Observable.just(nil)
        }
        
        let path = "users/\(uid)"
            
            return readValue(path: path, type: UserDTO.self)
                .map { dto in
                    return dto.toModel()
                }
                .catch { error in
                    print("❌ 유저 정보 디코딩 실패 - nil반환: \(error.localizedDescription)")
                    return Observable.just(nil)
                }
    }
    
    /// Uid기반 유저 정보 가져오기 - read
    /// - Parameter uid: uid
    /// - Returns: Observable<User?>
    public func fetchUser(uid: String) -> Observable<Domain.User?> {
        let path = "users/\(uid)"
            
            return readValue(path: path, type: UserDTO.self)
                .map { dto in
                    return dto.toModel()
                }
                .catch { error in
                    print("❌ 유저 정보 디코딩 실패: \(error.localizedDescription)")
                    return Observable.just(nil)
                }
    }
    
    /// 유저 업데이트 - update
    /// - Parameter user: user구조체
    /// - Returns: Observable<Result<User, LoginError>>
    public func updateUser(user: Domain.User) -> Observable<Result<Domain.User, LoginError>> {
        let path = "users/\(user.uid)"
        let dto = user.toDTO()
        
        return updateValue(path: path, value: dto)
            .map { success -> Result<Domain.User, LoginError> in
                if success {
                    return .success(user)
                } else {
                    return .failure(.updateUserError)
                }
            }
    }
    
    /// 유저 삭제 - delete
    /// - Parameter uid: Uid
    /// - Returns: 삭제유무
    public func deleteUser(uid: String) -> Observable<Bool> {
        // 1. 유저 정보 읽기(groudId 확보용)
        return fetchUser(uid: uid)
            .flatMap { (user: Domain.User!) -> Observable<Bool> in
                guard let groudId = user.groupId else {
                    // 그룹이 없으면 곧바로 성공
                    return .just(true)
                }
                // 2. 그룹 멤버 경로에서 삭제
                let memberPath = "groups/\(groudId)/members/\(uid)"
                return self.deleteValue(path: memberPath)
            }
            .flatMap { (groupRemovalSuccess: Bool) -> Observable<Bool> in
                guard groupRemovalSuccess else {
                    // 그룹에서 제거 실패
                    return .just(false)
                }
                // 3 users/{uid} 데이터 삭제
                let userPath = "users/\(uid)"
                return self.deleteValue(path: userPath)
            }
            .flatMap { (userRemoved: Bool) -> Observable<Bool> in
                guard userRemoved else {
                    // 유저 데이터 삭제 실패
                    return .just(false)
                }
                // 4. Firebase Auth 계정 삭제
                guard let currentUser = Auth.auth().currentUser,
                      currentUser.uid == uid else {
                    return .just(false)
                }
                return Observable<Bool>.create { observer in
                    currentUser.delete { error in
                        observer.onNext(error == nil)
                        observer.onCompleted()
                    }
                    return Disposables.create()
                }
            }
    }
}

// MARK: - 그룹 관련
extension FirebaseAuthManager {
    /// 초대 코드 생성기
    private func generateInviteCode(length: Int = 6) -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).compactMap { _ in characters.randomElement() })
    }
    
    /// 그룹 만들기
    /// - Parameter groupName: 그룹 이름
    /// - Returns: Observable<Result<(groupId: String, inviteCode: String), GroupError>>
    public func createGroup(groupName: String) -> Observable<Result<(groupId: String, inviteCode: String), GroupError>> {
        let newGroupRef = self.databaseRef.child("groups").childByAutoId()
        
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ 현재 로그인된 유저 없음")
            return Observable.just(.failure(.makeHostError))
        }
        
        let inviteCode = self.generateInviteCode()
        let joinedAt = Date().toISO8601String()
        
        let groupData = HCGroup(
            groupId: newGroupRef.key ?? "",
            groupName: groupName,
            createdAt: Date(),
            hostUserId: currentUserId,
            inviteCode: inviteCode,
            members: [currentUserId: joinedAt],
            postsByDate: [:]
        )
        
        return setValue(path: "groups/\(newGroupRef.key ?? "")", value: groupData.toDTO())
            .map { success -> Result<(groupId: String, inviteCode: String), GroupError> in
                if success {
                    print("✅ 그룹 생성 성공! ID: \(newGroupRef.key ?? "")")
                    return .success((groupId: newGroupRef.key ?? "", inviteCode: inviteCode))
                } else {
                    print("❌ 그룹 생성 실패")
                    return .failure(.makeHostError)
                }
            }
    }
    
    /// 그룹 Create후 유저속성에 추가
    /// - Parameter groupId: 그룹 Id
    /// - Returns: Observable<Result<Void, GroupError>>
    public func updateUserGroupId(groupId: String) -> Observable<Result<Void, GroupError>> {
        
        /// 현재 유저의 UID를 구한다
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ 현재 로그인된 유저 없음")
            return Observable.just(.failure(.makeHostError))
        }
            
        /// UID 기반으로 저장할 위치경로를 정한다
        let path = "users/\(currentUserId)"
        let update = ["groupId": groupId]
        
        return updateValue(path: path, value: update)
            .map { success -> Result<Void, GroupError> in
                if success {
                    return .success(())
                } else {
                    return .failure(.makeHostError)
                }
        }
    }
    
    /// 그룹 Read
    /// - Parameter groupId: 그룹 ID
    /// - Returns: Observable<Result<HCGroup, GroupError>>
    public func fetchGroup(groupId: String) -> Observable<Result<HCGroup, GroupError>> {
        return readValue(path: "groups/\(groupId)", type: HCGroupDTO.self)
            .map { dto in
                if let group = dto.toModel() {
                    return .success(group)
                } else {
                    return .failure(.fetchGroupError)
                }
            }
            .catch { error in
                print("❌ 그룹 정보 가져오기 실패: \(error.localizedDescription)")
                return Observable.just(.failure(.fetchGroupError))
            }
    }
    
    
    /// 그룸 참가
    /// - Parameter inviteCode: 초대 코드
    /// - Returns: Observable<Result<HCGroup, GroupError>>
    public func joinGroup(inviteCode: String) -> Observable<Result<HCGroup, GroupError>> {
        return readValue(path: "groups", type: [String: HCGroupDTO].self)
            .flatMap { groupDict -> Observable<Result<HCGroup, GroupError>> in
                let groups = groupDict.compactMapValues { $0.toModel() }
                
                guard let matched = groups.values.first(where: { $0.inviteCode == inviteCode }) else {
                    print("❌ 초대코드로 일치하는 그룹 없음")
                    return Observable.just(.failure(.fetchGroupError))
                }
                
                guard let currentUID = Auth.auth().currentUser?.uid else {
                    return Observable.just(.failure(.makeHostError))
                }
                
                let groupId = matched.groupId
                let membersPath = "groups/\(groupId)/members"
                let groupPath = "groups/\(groupId)"
                
                // ✅ [uid: joinedAt] 형태로 불러오기
                return self.readValue(path: membersPath, type: [String: String].self)
                    .catchAndReturn([:]) // 멤버가 없을 수도 있으므로 안전하게
                    .flatMap { existingMembers in
                        var newMembers = existingMembers
                        let joinedAt = Date().toISO8601String()
                        
                        newMembers[currentUID] = joinedAt
                        
                        // ✅ members 업데이트
                        let membersDict: [String: Any] = ["members": newMembers]
                        
                        return Observable.create { observer in
                            self.databaseRef.child(groupPath).updateChildValues(membersDict) { error, _ in
                                if let error = error {
                                    print("❌ members 업데이트 실패: \(error.localizedDescription)")
                                    observer.onNext(false)
                                } else {
                                    print("✅ members 업데이트 성공")
                                    observer.onNext(true)
                                }
                                observer.onCompleted()
                            }
                            return Disposables.create()
                        }
                    }
                    .flatMap { success in
                        if success {
                            return self.updateUserGroupId(groupId: groupId)
                                .map { updateResult in
                                    switch updateResult {
                                    case .success:
                                        return Result<HCGroup, GroupError>.success(matched)
                                    case .failure:
                                        return Result<HCGroup, GroupError>.failure(.makeHostError)
                                    }
                                }
                        } else {
                            return .just(.failure(.makeHostError))
                        }
                    }
            }
            .catch { error in
                print("❌ 그룹 조회 실패: \(error)")
                return Observable.just(.failure(.fetchGroupError))
            }
    }
    
    
    
    /// 그룹 업데이트
    /// - Parameters:
    ///   - path: 업데이트할 경로
    ///   - post: 올릴 포스트
    /// - Returns: 업데이트 결과
    public func updateGroup(path: String, post: PostDTO) -> Observable<Bool> {
        return updateValue(path: path, value: post)
    }
}

// MARK: - 댓글 관련
extension FirebaseAuthManager {
    public func addComment(path: String, value: CommentDTO) -> Observable<Bool> {
        return setValue(path: path, value: value)
    }
    public func deleteComment(path: String) -> Observable<Bool> {
        return deleteValue(path: path)
    }
}

// MARK: - 실시간 스냅샷 관련
extension FirebaseAuthManager {
    /// 실시간 스냅샷 감지
    /// Firebase Realtime Database에서 특정 경로(path)의 데이터를 **실시간으로 관찰**합니다.
    /// 해당 경로의 데이터가 변경될 때마다 최신 데이터를 가져와 스트림으로 방출합니다.
    /// - Parameters:
    ///   - path: Firebase Realtime Database 내에서 데이터를 관찰할 경로 문자열
    ///   - type: 디코딩할 모델 타입 (`Decodable`을 준수하는 타입)
    /// - Returns: 실시간으로 감지된 데이터를 방출하는 `Observable<T>`
    public func observeValueStream<T: Decodable>(path: String, type: T.Type) -> Observable<T> {
        return Observable.create { observer in
            let ref = self.databaseRef.child(path)
            let handle = ref.observe(.value) { snapshot in
                
                guard let value = snapshot.value else {
                    print("📛 실시간 observe: value 없음")
                    observer.onError(NSError(domain: "firebase", code: -1, userInfo: [NSLocalizedDescriptionKey: "값이 없음"]))
                    return
                }
                
                // 🔴 안전성: 직렬화 가능한 타입인지 검사
               guard JSONSerialization.isValidJSONObject(value) else {
                   observer.onError(NSError(domain: "firebase", code: -2, userInfo: [NSLocalizedDescriptionKey: "직렬화 불가능한 타입"]))
                   return
               }
                
                do {
                    let data = try JSONSerialization.data(withJSONObject: value, options: [])
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    observer.onNext(decoded)
                } catch {
                    print("❌ observeValueStream 디코딩 실패: \(error.localizedDescription)")
                    observer.onError(error)
                }
            }

            return Disposables.create {
                ref.removeObserver(withHandle: handle)
            }
        }
    }
}
