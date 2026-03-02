//
//  FirebaseAuthManager.swift
//  Haruhancut
//
//  Created by 김동현 on 6/17/25.
//
import FirebaseAuth
import FirebaseDatabase
import FirebaseMessaging
import RxSwift
import RxCocoa
import Core
import Domain

/*
 MARK: 단발성 작업의 결과가 1회로 보장되도록(onNext + onCompleted) 스트림 의미를 명확히 하기 위해 Observable 대신 Single 사용하였다
 - 네트워크 요청 / DB 단건 조회 / Firebase write
 - 결과는 성공 or 실패 중 하나
 - 지속적으로 값을 방출하지 않는다
 
 Single은 결과 개수를 타입 레벨에서 제한한다
 - 성공 시: 값 1번 + 자동 종료
 - 실패 시: 에러로 즉시 종료
 - Observable처럼 onNext 여러 번 방출되는 실수를 원천 차단
 
 종료(onCompleted) 누락 가능성을 제거한다
 - Observable은 onCompleted를 직접 호출해야 함
 - Single은 success / failure 호출 시 자동 종료됨
 - subscribe가 불필요하게 살아있는 상태를 방지
 
 상위 계층의 오해를 줄인다
 - Observable: 값이 여러 번 올 수 있는지 추론 필요
 - Single: "한 번 결과 받고 끝"이라는 계약이 명확
 - take(1), first() 같은 방어 코드 불필요

 API 의도를 명확하게 드러낸다
 - func fetchUser() -> Single<User>
      → 이 함수는 반드시 단일 결과를 반환
 - 구현보다 '의미'를 타입으로 표현
 
 [Observable]
 enum Event<Element> {
     case next(Element)
     case error(Error)
     case completed
 }

 [Single]
 - Observable을 제약 걸어놓은 타입
 - (success(Element)) OR (failure(Error))
 - (success(Element) => 래핑되있음 .onNext(value) → .onCompleted
 - (failure(Error))  => 래핑되있음 .onError(error)
 
 한 번 끝나는 작업 → Single<T>
 실시간 스트림 → Observable<T>
 Result ❌
 실패는 무조건 onError
 */

public enum FirebaseError: Error {
    
    // Encoding / Decoding
    case encodingFailed
    case decodingFailed
    
    // Firebase Realtime Database
    case permissionDenied
    case pathNotFound
    case invalidData
    
    // Firebase FCM
    case noFCMToken
    case unknown(Error)
}

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

/*
 Infra
 - 성공: Observable<T> / Observable<Void>
 - 실패: onError(Error)
 */
public protocol FirebaseAuthManagerProtocol {
    // MARK: - 제네릭
    func setValue<T: Encodable>(path: String, value: T) -> Single<Void>      // create
    func readValue<T: Decodable>(path: String, type: T.Type) -> Single<T>    // read
    func updateValue<T: Encodable>(path: String, value: T) -> Single<Void>   // update
    func deleteValue(path: String) -> Single<Void>                           // dellete
    
    // MARK: - 유저관련
    // Firebase Auth 인증
    // func authenticateUser(prividerID: String, idToken: String, rawNonce: String?) -> Single<Void>
    func authenticateUser(providerID: String, idToken: String, rawNonce: String?) -> Single<String>
    
    // Realtime DB 유저 생성
    func registerUserToRealtimeDatabase(user: Domain.User) -> Single<Domain.User>
    
    // 내 정보 조회
    // func fetchMyInfo() -> Single<Domain.User?>
    
    // 특정 유저 조회
    func fetchUser(uid: String) -> Single<Domain.User?>
    
    // 유저 업데이트
    func updateUser(user: Domain.User) -> Single<Void>
    
    // 유저 삭제 (Auth + DB)
    func deleteUser(uid: String) -> Single<Void>
    func patchUser(uid: String, fields: [String: Any]) -> Single<Void>       // patch
    func signOut() -> Single<Void>
    
    
    // MARK: - 그룹관련
    // 그룹 생성
    func createGroup(groupName: String) -> Single<(groupId: String, inviteCode: String)>
    
    // 유저 groupId 업데이트
    func updateUserGroupId(groupId: String) -> Single<Void>
    
    // 그룹 조회
    func fetchGroup(groupId: String) -> Single<HCGroup>
    
    // 그룹 참가
    func joinGroup(inviteCode: String) -> Single<HCGroup>
    
    // 그룹 게시글 업데이트
    func updateGroup(path: String, post: PostDTO) -> Single<Void>
    
    
    // MARK: - 댓글관련
    // 댓글 작성
    func addComment(path: String, value: CommentDTO) -> Single<Void>
    
    // 댓글 삭제
    func deleteComment(path: String) -> Single<Void>
    
    // MARK: - Realtime Observe
    // 실시간 스냅샷 스트림
    func observeValueStream<T: Decodable>(path: String, type: T.Type) -> Observable<T>
    func generateFcmToken() -> Single<String>
}

public final class FirebaseAuthManager: FirebaseAuthManagerProtocol {
   
    public init() {}
    private var databaseRef: DatabaseReference {
        Database.database(url: Constants.Firebase.realtimeURL).reference()
    }
}

// MARK: - Realtime Database 제네릭 함수
extension FirebaseAuthManager {
    
    
    public func setValue<T: Encodable>(path: String, value: T) -> Single<Void> {
        return Single.create { single in
            do {
                let data = try JSONEncoder().encode(value)
                let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                
                self.databaseRef.child(path).setValue(dict) { error, _ in
                    if let error = error {
                        print("🔥 setValue 실패: \(error.localizedDescription)")
                        
                        single(.failure(FirebaseError.unknown(error)))
                    } else {
                        single(.success(()))
                    }
                }
            } catch {
                single(.failure(FirebaseError.encodingFailed))
            }
            return Disposables.create()
        }
    }
    
    /// Read - 1회 요청
    /// - Parameters:
    ///   - path: 경로
    ///   - type: 값
    /// - Returns: Observable<T>
    public func readValue<T: Decodable>(path: String, type: T.Type) -> Single<T> {
        return Single.create { single in
            self.databaseRef.child(path).observeSingleEvent(of: .value) { snapshot in
                guard let value = snapshot.value else {
                    single(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "값이 존재하지 않음"])))
                    return
                }
                
                do {
                    guard JSONSerialization.isValidJSONObject(value) else {
                        throw NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "유효하지 않은 JSON 객체"])
                    }
                    
                    let data = try JSONSerialization.data(withJSONObject: value, options: [])
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    single(.success(decoded))
                } catch {
                    single(.failure(FirebaseError.decodingFailed))
                }
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
    public func updateValue<T: Encodable>(path: String, value: T) -> Single<Void> {
        return Single.create { single in
            guard let dict = value.toDictionary() else {
                single(.failure(FirebaseError.encodingFailed))
                return Disposables.create()
            }
            
            self.databaseRef.child(path).updateChildValues(dict) { error, _ in
                if let error = error {
                    print("❌ updateValue 실패: \(error.localizedDescription)")
                    single(.failure(error))
                } else {
                    single(.success(()))
                }
            }
            
            return Disposables.create()
        }
    }

    /// Delete
    /// - Parameter path: 삭제할 Firebase realtime 데이터 경로
    /// - Returns: 삭제 성공 여부 방출하는 Observable<Bool>
    public func deleteValue(path: String) -> Single<Void> {
        return Single.create { single in
            self.databaseRef.child(path).removeValue { error, _ in
                if let error = error {
                    print("❌ deleteValue 실패: \(error.localizedDescription)")
                    single(.failure(error))
                } else {
                    print("✅ deleteValue 성공: \(path)")
                    single(.success(()))
                }
            }
            return Disposables.create()
        }
    }
}

// MARK: - 유저 관련
extension FirebaseAuthManager {
    
    private func waitForAuthUser_() -> Single<String> {
        Single.create { single in
            let handle = Auth.auth().addStateDidChangeListener { _, user in
                if let user {
                    single(.success(user.uid))
                }
            }

            return Disposables.create {
                Auth.auth().removeStateDidChangeListener(handle)
            }
        }
    }
    
    private func waitForAuthUser() -> Single<String> {
        Single.create { single in
            let handle = Auth.auth().addStateDidChangeListener { _, user in
                guard let user else { return }

                // 🔑 핵심: currentUser가 실제로 세팅될 때까지 보장
                if Auth.auth().currentUser?.uid == user.uid {
                    single(.success(user.uid))
                }
            }

            return Disposables.create {
                Auth.auth().removeStateDidChangeListener(handle)
            }
        }
    }
    
    public func authenticateUser(
            providerID: String,
            idToken: String,
            rawNonce: String?
        ) -> Single<String> {

            guard let provider = ProviderID(rawValue: providerID) else {
                return .error(FirebaseError.invalidData)
            }

            let credential = OAuthProvider.credential(
                providerID: provider.authProviderID,
                idToken: idToken,
                rawNonce: rawNonce ?? ""
            )

            return Single<String>.create { single in
                Auth.auth().signIn(with: credential) { _, error in
                    if let error {
                        single(.failure(FirebaseError.unknown(error)))
                        return
                    }

                    // ❗️Auth 성공은 "uid 확보"로 확정
                    guard let uid = Auth.auth().currentUser?.uid else {
                        single(.failure(LoginError.authError))
                        return
                    }

                    single(.success(uid))
                }

                return Disposables.create()
            }
        }
    
    /// Firebase Realtime Database에 유저 정보를 저장하고, 저장된 User를 반환 - create
    /// - Parameter user: 저장할 User 객체
    /// - Returns: Result<User, LoginError>
    public func registerUserToRealtimeDatabase(user: Domain.User) -> Single<Domain.User> {
        guard let firebaseUID = Auth.auth().currentUser?.uid else {
            return .error(FirebaseError.permissionDenied)
        }

        var userEntity = user
        userEntity.uid = firebaseUID
        let userDto = userEntity.toDTO()
        let path = "users/\(firebaseUID)"

        return setValue(path: path, value: userDto)
            .map { userEntity }
    }
    
    /// Uid기반 유저 정보 가져오기 - read
    /// - Parameter uid: uid
    /// - Returns: Observable<User?>
    public func fetchUser(uid: String) -> Single<Domain.User?> {
        let path = "users/\(uid)"
            
            return readValue(path: path, type: UserDTO.self)
                .map { dto in
                    return dto.toModel()
                }
                .catch { error in
                    print("❌ 유저 정보 디코딩 실패: \(error.localizedDescription)")
                    return Single.just(nil)
                }
    }
    
    /// 유저 업데이트 - update
    /// - Parameter user: user구조체
    /// - Returns: Observable<Result<User, LoginError>>
    public func updateUser(user: Domain.User) -> Single<Void> {
        let path = "users/\(user.uid)"
        let dto = user.toDTO()
        
        return updateValue(path: path, value: dto)
    }

    
    /// 유저 삭제 - delete
    /// - Parameter uid: Uid
    /// - Returns: 삭제유무
    public func deleteUser(uid: String) -> Single<Void> {
        return fetchUser(uid: uid)
            // 1) user 읽어서 groupId 확인
            .flatMap { user -> Single<Void> in
                guard let user else { return .error(FirebaseError.pathNotFound)}
                
                // 1-1. 그룹 멤버 경로에서 삭제
                if let groupId = user.groupId {
                    let memberPath = "groups/\(groupId)/members/\(uid)"
                    return self.deleteValue(path: memberPath) // Observable<Void>
                }
                
                // 1-2 그룹이 없으면 이 단계는 스킵되지만 성공으로 간주한다
                return .just(()) // Observable<Void>
            }
            // 2) users/{uid} 삭제
            .flatMap { _ -> Single<Void> in
                self.deleteValue(path: "users/\(uid)")
            }
            // 3) Firebase Auth 계정 삭제
            .flatMap { _ -> Single<Void> in
                guard let currentUser = Auth.auth().currentUser, currentUser.uid == uid else {
                    return .error(FirebaseError.permissionDenied)
                }
                
                return Single.create { single in
                    currentUser.delete { error in
                        if let error = error {
                            single(.failure(FirebaseError.unknown(error)))
                        } else {
                            single(.success(()))
                        }
                    }
                    return Disposables.create()
                }
            }
    }
    
    /// 유저 일부 수정
    /// - Parameter uid: Uid
    /// - Returns: 업데이트 성공유무
    public func patchUser(uid: String, fields: [String: Any]) -> Single<Void> {
        let path = "users/\(uid)"
        return Single.create { single in
            self.databaseRef
                .child(path)
                .updateChildValues(fields) { error, _ in
                    if let error {
                        single(.failure(FirebaseError.unknown(error)))
                    } else {
                        single(.success(()))
                    }
                }
            return Disposables.create()
        }
    }
    
    public func signOut() -> Single<Void> {
        return Single.create { single in
            do {
                try Auth.auth().signOut()
                single(.success(()))
            } catch {
                single(.failure(FirebaseError.unknown(error)))
            }
            
            return Disposables.create()
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
    public func createGroup(groupName: String) -> Single<(groupId: String, inviteCode: String)> {
        
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ 현재 로그인된 유저 없음")
            return .error(FirebaseError.permissionDenied)
        }
        
        let newGroupRef = self.databaseRef.child("groups").childByAutoId()
        let groupId = newGroupRef.key ?? UUID().uuidString
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
            .map { (groupId: groupId, inviteCode: inviteCode) }
    }
    
    /// 그룹 Create후 유저속성에 추가
    /// - Parameter groupId: 그룹 Id
    /// - Returns: Observable<Result<Void, GroupError>>
    public func updateUserGroupId(groupId: String) -> Single<Void> {
        
        /// 현재 유저의 UID를 구한다
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ 현재 로그인된 유저 없음")
            return .error(FirebaseError.permissionDenied)
        }
            
        /// UID 기반으로 저장할 위치경로를 정한다
        let path = "users/\(currentUserId)"
        let update = ["groupId": groupId]
        
        return updateValue(path: path, value: update)
        }
    
    /// 그룹 Read
    /// - Parameter groupId: 그룹 ID
    /// - Returns: Observable<Result<HCGroup, GroupError>>
    public func fetchGroup(groupId: String) -> Single<HCGroup> {
        return readValue(path: "groups/\(groupId)", type: HCGroupDTO.self)
            .flatMap { dto -> Single<HCGroup> in
                if let model = dto.toModel() {
                    return .just(model)
                } else {
                    return .error(FirebaseError.decodingFailed)
                }
            }
    }
    
    /// 그룸 참가
    /// - Parameter inviteCode: 초대 코드
    /// - Returns: Observable<Result<HCGroup, GroupError>>
    public func joinGroup(inviteCode: String) -> Single<HCGroup> {
        guard let currentUID = Auth.auth().currentUser?.uid else {
            return Single.error(FirebaseError.permissionDenied)
        }

        return readValue(path: "groups", type: [String: HCGroupDTO].self)
            .map { dict in
                dict.compactMapValues { $0.toModel() }
            }
            .flatMap { groups -> Single<HCGroup> in
                guard let group = groups.values.first(where: { $0.inviteCode == inviteCode }) else {
                    return Single.error(FirebaseError.pathNotFound)
                }

                let groupId = group.groupId
                let groupPath = "groups/\(groupId)"
                let membersPath = "\(groupPath)/members"

                return self.readValue(path: membersPath, type: [String: String].self)
                    .catchAndReturn([:])
                    .flatMap { members -> Single<Void> in
                        var newMembers = members
                        newMembers[currentUID] = Date().toISO8601String()
                        return self.updateValue(path: groupPath, value: ["members": newMembers])
                    }
                    .flatMap {
                        self.updateUserGroupId(groupId: groupId)
                    }
                    .map {
                        group
                    }
            }
    }
    
    /// 그룹 업데이트
    /// - Parameters:
    ///   - path: 업데이트할 경로
    ///   - post: 올릴 포스트
    /// - Returns: 업데이트 결과
    public func updateGroup(path: String, post: PostDTO) -> Single<Void> {
        return updateValue(path: path, value: post)
    }
}

// MARK: - 댓글 관련
extension FirebaseAuthManager {
    public func addComment(path: String, value: CommentDTO) -> Single<Void> {
        return setValue(path: path, value: value)
    }
    public func deleteComment(path: String) -> Single<Void> {
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

extension FirebaseAuthManager {
    public func generateFcmToken() -> Single<String> {
        return Single.create { single in
            Messaging.messaging().token { token, error in
                if let error = error {
                    print("⚠️ FCM 토큰 발급 실패: \(error.localizedDescription)")
                    print("⚠️ FCM 토큰을 받을 수 없는 기기라서 넘아갑니다.")
                    single(.failure(FirebaseError.unknown(error)))
                }
                
                guard let token = token else {
                    single(.failure(FirebaseError.noFCMToken))
                    return
                }
                
                single(.success(token))
            }
            return Disposables.create()
        }
    }
}
