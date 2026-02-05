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
    func uploadImage(image: UIImage, path: String) -> Observable<URL>
    func deleteImage(path: String) -> Observable<Void>
}

public final class FirebaseStorageManager: FirebaseStorageManagerProtocol {
    public init() {}
}

extension FirebaseStorageManager {
    public func uploadImage(image: UIImage, path: String) -> Observable<URL> {
        return Observable.create { observer in
            guard let data = image.jpegData(compressionQuality: 0.8) else {
                print("❌ JPEG 변환 실패")
                observer.onError(FirebaseError.encodingFailed)
                return Disposables.create()
            }
            
            let ref = Storage.storage().reference().child(path)
            
            // 업로드 시작
            ref.putData(data, metadata: nil) { _, error in
                if let error = error {
                    print("❌ 업로드 실패: \(error.localizedDescription)")
                    observer.onError(FirebaseError.unknown(error))
                    return
                }
                
                // 업로드 성공 후 다운로드 uri 요청
                ref.downloadURL { url, error in
                    if let error = error {
                        print("❌ downloadURL 실패: \(error.localizedDescription)")
                        observer.onError(FirebaseError.unknown(error))
                    } else if let url = url {
                        print("✅ 이미지 업로드 및 URL 확보 성공: \(url.absoluteString)")
                        observer.onNext(url)
                        observer.onCompleted()
                    } else {
                        print("❌ URL 없음 (downloadURL nil)")
                        observer.onError(FirebaseError.invalidData)
                    }
                }
            }
            return Disposables.create()
        }
    }
    
    public func deleteImage(path: String) -> Observable<Void> {
        return Observable.create { observer in
            let ref = Storage.storage().reference().child(path)
            ref.delete { error in
                if let error = error {
                    print("❌ 이미지 삭제 실패: \(error.localizedDescription)")
                    observer.onError(FirebaseError.unknown(error))
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
}
