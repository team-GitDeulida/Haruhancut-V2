//
//  FirebaseAuthManager.swift
//  Core
//
//  Created by 김동현 on 1/13/26.
//

import FirebaseAuth
import FirebaseDatabase
import RxSwift

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

extension FirebaseAuthManager {
    // create
    func setValure<T :Encodable>(path: String, value: T) -> Observable<Bool> {
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
}
