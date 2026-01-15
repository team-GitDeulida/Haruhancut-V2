//
//  FirebaseAuthManager.swift
//  Core
//
//  Created by 김동현 on 1/13/26.
//

import FirebaseAuth
import FirebaseDatabase
import RxSwift
import Core
import Domain

enum ProviderID: String {
    case kakao
    case apple
    var authProviderID: AuthProviderID {
        switch self {
        case .kakao: return .custom("oidc.kakao")
        case .apple: return .apple
        }
    }
}

public final class FirebaseAuthManager {
    
    private var databaseRef: DatabaseReference {
        Database.database(url: Constants.Firebase.realtimeURL).reference()
    }
    
    public init() {}
}

// MARK: - CRUD
extension FirebaseAuthManager {
    /// Create or Overwrite
    /// - Parameters:
    ///   - path: 경로
    ///   - value: 값
    /// - Returns: Observable<Bool>
    func setValue<T: Encodable>(path: String, value: T) -> Observable<Bool> {
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
    func readValue<T: Decodable>(path: String, type: T.Type) -> Observable<T> {
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
    func updateValue<T: Encodable>(path: String, value: T) -> Observable<Bool> {
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
    func deleteValue(path: String) -> Observable<Bool> {
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
    func authenticateUser(prividerID: String, idToken: String, rawNonce: String?) -> Observable<Result<Void, LoginError>> {
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
    func registerUserToRealtimeDatabase(user: Domain.User) -> Observable<Result<Domain.User, LoginError>> {
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
    func fetchMyInfo() -> Observable<Domain.User?> {
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
    func fetchUser(uid: String) -> Observable<Domain.User?> {
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
    func updateUser(user: Domain.User) -> Observable<Result<Domain.User, LoginError>> {
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
    func deleteUser(uid: String) -> Observable<Bool> {
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
