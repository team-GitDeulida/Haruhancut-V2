//
//  FeedWidgetSynchronizer.swift
//  HomeFeatureV2
//
//  Created by 김동현 on 10/10/26.
//

import Core
import Domain
import Foundation
import HomeFeatureV2Interface
import WidgetKit
import WidgetSupport

/// 홈 화면 위젯(`PhotoWidget`)이 읽는 저장소를 V2 홈의 오늘 사진과 맞추는 계약입니다.
protocol FeedWidgetSynchronizing {

    /// 위젯용 사용자와 오늘 가장 최근 게시물의 사진을 저장합니다.
    ///
    /// - Parameters:
    ///   - user: 위젯이 그룹을 찾을 때 쓰는 현재 사용자.
    ///   - postsByDate: 그룹에서 불러온 날짜별 게시물.
    func synchronize(
        user: User?,
        postsByDate: [String: [Post]]
    )

    /// 삭제한 게시물의 사진을 위젯 저장소에서 지웁니다.
    ///
    /// - Parameters:
    ///   - post: 삭제한 게시물.
    ///   - user: 위젯 저장소의 그룹을 찾을 때 쓰는 현재 사용자.
    func removePhoto(
        of post: Post,
        user: User?
    )
}

/// 위젯이 읽는 App Group 저장소에 접근하는 계약입니다.
protocol FeedWidgetStoring {
    func saveUser(_ user: User)

    func hasPhoto(
        groupId: String,
        dateKey: String,
        identifier: String
    ) -> Bool

    func savePhoto(
        data: Data,
        groupId: String,
        identifier: String
    ) throws

    func deletePhoto(
        groupId: String,
        dateKey: String,
        identifier: String
    )

    /// 위젯에 저장소를 다시 읽으라고 요청합니다.
    func reloadWidget()
}

/// V1 `HomeViewModel`이 하던 위젯 동기화를 V2 홈에서 수행합니다.
final class FeedWidgetSynchronizer: FeedWidgetSynchronizing {
    typealias ImageDataLoader = (
        URL,
        @escaping (Data?) -> Void
    ) -> Void

    private let store: FeedWidgetStoring
    private let loadImageData: ImageDataLoader

    /// - Parameters:
    ///   - store: 위젯 저장소. 기본값은 App Group 저장소입니다.
    ///   - loadImageData: 게시물 이미지를 내려받는 동작. 기본값은 `URLSession`입니다.
    init(
        store: FeedWidgetStoring = AppGroupFeedWidgetStore(),
        loadImageData: @escaping ImageDataLoader =
            FeedWidgetSynchronizer.loadWithURLSession
    ) {
        self.store = store
        self.loadImageData = loadImageData
    }

    func synchronize(
        user: User?,
        postsByDate: [String: [Post]]
    ) {
        guard
            let user,
            let groupId = user.groupId
        else {
            return
        }
        store.saveUser(user)

        guard
            let post = Self.latestTodayPost(in: postsByDate),
            let imageURL = URL(string: post.imageURL),
            !store.hasPhoto(
                groupId: groupId,
                dateKey: Self.dateKey(of: post),
                identifier: post.postId
            )
        else {
            return
        }

        let store = store
        loadImageData(imageURL) { data in
            guard let data else {
                return
            }
            do {
                try store.savePhoto(
                    data: data,
                    groupId: groupId,
                    identifier: post.postId
                )
                store.reloadWidget()
            } catch {
                Logger.e("FeedWidgetSynchronizer savePhoto failed: \(error)")
            }
        }
    }

    func removePhoto(
        of post: Post,
        user: User?
    ) {
        guard let groupId = user?.groupId else {
            return
        }
        store.deletePhoto(
            groupId: groupId,
            dateKey: Self.dateKey(of: post),
            identifier: post.postId
        )
        store.reloadWidget()
    }
}

extension FeedWidgetSynchronizer {
    /// 화면 모드에 맞는 동기화 객체를 만듭니다.
    ///
    /// 관리자 미리보기는 다른 그룹을 표시하므로, 내 위젯을 덮어쓰지 않도록 동기화하지 않습니다.
    ///
    /// - Parameter mode: 홈 화면 표시 모드.
    /// - Returns: 내 그룹을 표시할 때만 동기화 객체.
    static func make(
        for mode: HomePresentationMode
    ) -> FeedWidgetSynchronizing? {
        mode.isReadOnly ? nil : FeedWidgetSynchronizer()
    }

    /// 오늘 올라온 게시물 중 가장 최근 게시물을 찾습니다.
    static func latestTodayPost(
        in postsByDate: [String: [Post]]
    ) -> Post? {
        postsByDate.values
            .flatMap { $0 }
            .filter { $0.isToday }
            .max { $0.createdAt < $1.createdAt }
    }

    /// 위젯 저장소의 날짜 폴더 이름입니다.
    ///
    /// 저장(`WidgetPhotoStore`)과 위젯(`PhotoWidget`)이 쓰는 기기 시간대 기준 날짜와 맞춥니다.
    static func dateKey(of post: Post) -> String {
        post.createdAt.widgetDateKey()
    }

    static func loadWithURLSession(
        url: URL,
        completion: @escaping (Data?) -> Void
    ) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            completion(data)
        }
        .resume()
    }
}

/// 위젯과 공유하는 App Group 저장소입니다.
struct AppGroupFeedWidgetStore: FeedWidgetStoring {
    /// `HaruhancutWidget`의 `PhotoWidget.kind`와 같아야 합니다.
    private static let photoWidgetKind = "PhotoWidget"

    func saveUser(_ user: User) {
        WidgetSessionStore.saveUser(user)
    }

    func hasPhoto(
        groupId: String,
        dateKey: String,
        identifier: String
    ) -> Bool {
        guard
            let folder = WidgetPaths.photosFolder(
                groupId: groupId,
                dateKey: dateKey
            ),
            let files = try? FileManager.default.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: nil
            )
        else {
            return false
        }
        return files.contains {
            $0.lastPathComponent.hasSuffix("-\(identifier).jpg")
        }
    }

    func savePhoto(
        data: Data,
        groupId: String,
        identifier: String
    ) throws {
        try WidgetPhotoStore.shared.saveImage(
            data: data,
            groupId: groupId,
            identifier: identifier
        )
    }

    func deletePhoto(
        groupId: String,
        dateKey: String,
        identifier: String
    ) {
        WidgetPhotoStore.shared.deleteImage(
            groupId: groupId,
            dateKey: dateKey,
            identifier: identifier
        )
    }

    /// 이미지 다운로드 완료 콜백(백그라운드)에서도 불리므로 메인 스레드에서 요청합니다.
    func reloadWidget() {
        DispatchQueue.main.async {
            WidgetCenter.shared.reloadTimelines(
                ofKind: Self.photoWidgetKind
            )
        }
    }
}
