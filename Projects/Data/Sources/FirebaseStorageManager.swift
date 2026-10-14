//
//  FirebaseStorageManager.swift
//  Data
//
//  Created by 김동현 on 1/20/26.
//

import UIKit
import FirebaseStorage
import RxSwift

public protocol FirebaseStorageManagerProtocol {
    func uploadImage(image: UIImage, path: String) -> Single<URL>
    func deleteImage(path: String) -> Single<Void>
}

public final class FirebaseStorageManager: FirebaseStorageManagerProtocol {
    /// 올리거나 지우기 전에 네트워크 연결을 확인합니다. 처음 쓸 때 꺼내 감시를 시작합니다.
    private let connection: () -> NetworkReachability

    public convenience init() {
        self.init(connection: { .shared })
    }

    init(connection: @escaping () -> NetworkReachability) {
        self.connection = connection
    }
}

extension FirebaseStorageManager {
    /// 네트워크가 끊겨 있으면 올리지 않고 `FirebaseError.offline`으로 끝납니다.
    public func uploadImage(image: UIImage, path: String) -> Single<URL> {
        let upload = Single<URL>.create { single in
            guard let data = image.jpegData(compressionQuality: 0.8) else {
                print("❌ JPEG 변환 실패")
                single(.failure(FirebaseError.encodingFailed))
                return Disposables.create()
            }
            
            let ref = Storage.storage().reference().child(path)
            
            // 업로드 시작
            ref.putData(data, metadata: nil) { _, error in
                if let error = error {
                    print("❌ 업로드 실패: \(error.localizedDescription)")
                    single(.failure(FirebaseError.unknown(error)))
                    return
                }
                
                // 업로드 성공 후 다운로드 uri 요청
                ref.downloadURL { url, error in
                    if let error = error {
                        print("❌ downloadURL 실패: \(error.localizedDescription)")
                        single(.failure(FirebaseError.unknown(error)))
                    } else if let url = url {
                        // print("✅ 이미지 업로드 및 URL 확보 성공: \(url.absoluteString)")
                        single(.success(url))
                    } else {
                        print("❌ URL 없음 (downloadURL nil)")
                        single(.failure(FirebaseError.invalidData))
                    }
                }
            }
            return Disposables.create()
        }
        return connection()
            .requireConnection()
            .andThen(upload)
    }
    
    /// 네트워크가 끊겨 있으면 지우지 않고 `FirebaseError.offline`으로 끝납니다.
    public func deleteImage(path: String) -> Single<Void> {
        let deletion = Single<Void>.create { single in
            let ref = Storage.storage().reference().child(path)
            ref.delete { error in
                if let error = error {
                    print("❌ 이미지 삭제 실패: \(error.localizedDescription)")
                    single(.failure(FirebaseError.unknown(error)))
                } else {
                    single(.success(()))
                }
            }
            return Disposables.create()
        }
        return connection()
            .requireConnection()
            .andThen(deletion)
    }
}
