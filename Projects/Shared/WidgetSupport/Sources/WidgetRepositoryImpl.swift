//
//  WidgetRepositoryImpl.swift
//  WidgetSupport
//
//  Created by 김동현 on 10/10/26.
//

import Domain
import Foundation
import RxSwift
import WidgetKit

/// 위젯과 공유하는 App Group 저장소로 `WidgetRepositoryProtocol`을 구현합니다.
///
/// 날짜 폴더 이름(`widgetDateKey`)과 사진 파일 이름 규칙은 `WidgetPhotoStore`가 정합니다.
public final class WidgetRepositoryImpl: WidgetRepositoryProtocol {

    /// `HaruhancutWidget`의 `PhotoWidget.kind`와 같아야 합니다
    private static let photoWidgetKind = "PhotoWidget"

    private let photoStore: WidgetPhotoStore
    private let sessionStore: WidgetSessionStore
    private let urlSession: URLSession

    /// - Parameters:
    ///   - photoStore: 사진 저장소. 기본값은 위젯과 공유하는 App Group 저장소입니다.
    ///   - sessionStore: 사용자 저장소. 기본값은 위젯과 공유하는 App Group 저장소입니다.
    ///   - urlSession: 게시물 이미지를 내려받을 세션.
    public init(photoStore: WidgetPhotoStore = .shared,
                sessionStore: WidgetSessionStore = WidgetSessionStore(),
                urlSession: URLSession = .shared
    ) {
        self.photoStore = photoStore
        self.sessionStore = sessionStore
        self.urlSession = urlSession
    }

    public func saveUser(_ user: User) {
        sessionStore.saveUser(user)
    }

    public func photoIdentifiers(groupId: String, date: Date) -> [String] {
        photoStore.photoIdentifiers(groupId: groupId, dateKey: date.widgetDateKey())
    }

    public func savePhoto(_ data: Data, groupId: String, identifier: String) throws {
        try photoStore.saveImage(data: data, groupId: groupId, identifier: identifier)
    }

    public func deletePhoto(groupId: String, date: Date, identifier: String) {
        photoStore.deleteImage(groupId: groupId, dateKey: date.widgetDateKey(), identifier: identifier)
    }

    public func fetchImageData(from url: URL) -> Single<Data> {
        Single.create { [urlSession] observer in
            let task = urlSession.dataTask(with: url) { data, _, error in
                if let data {
                    observer(.success(data))
                } else {
                    observer(.failure(error ?? URLError(.badServerResponse)))
                }
            }
            task.resume()
            return Disposables.create { task.cancel() }
        }
    }

    /// 작업 큐에서 불리므로 메인 스레드에서 요청합니다
    public func reloadWidget() {
        DispatchQueue.main.async {
            WidgetCenter.shared.reloadTimelines(ofKind: Self.photoWidgetKind)
        }
    }
}
