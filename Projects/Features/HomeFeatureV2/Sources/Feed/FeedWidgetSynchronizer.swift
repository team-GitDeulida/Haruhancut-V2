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

    /// 위젯용 사용자를 저장하고, 위젯에 오늘 가장 최근 게시물의 사진만 남깁니다.
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

    /// 날짜 폴더에 저장된 사진의 게시물 식별자 목록입니다.
    func photoIdentifiers(
        groupId: String,
        dateKey: String
    ) -> [String]

    /// 오늘 날짜 폴더에 사진을 저장합니다.
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
///
/// 그룹마다 위젯에 보여야 할 게시물(오늘 가장 최근 게시물)을 기억합니다. 다운로드가 끝났을 때
/// 그 게시물이 여전히 보여야 할 게시물일 때만 저장하므로, 캐시에 남은 삭제된 게시물이나
/// 다운로드 중 삭제된 게시물이 위젯에 남지 않습니다. 상태와 파일 작업은 `workQueue`에서
/// 순서대로 처리합니다.
final class FeedWidgetSynchronizer: FeedWidgetSynchronizing {
    typealias ImageDataLoader = (
        URL,
        @escaping (Data?) -> Void
    ) -> Void

    private let store: FeedWidgetStoring
    private let loadImageData: ImageDataLoader
    private let workQueue: DispatchQueue

    /// 그룹 ID별로 위젯에 보여야 할 게시물 ID입니다. `workQueue`에서만 접근합니다.
    private var displayedPostIDByGroupID: [String: String] = [:]

    /// 내려받는 중인 게시물 ID입니다. `workQueue`에서만 접근합니다.
    private var downloadingPostIDs: Set<String> = []

    /// - Parameters:
    ///   - store: 위젯 저장소. 기본값은 App Group 저장소입니다.
    ///   - loadImageData: 게시물 이미지를 내려받는 동작. 기본값은 `URLSession`입니다.
    ///   - workQueue: 상태와 파일 작업을 순서대로 처리할 직렬 큐.
    init(
        store: FeedWidgetStoring = AppGroupFeedWidgetStore(),
        loadImageData: @escaping ImageDataLoader =
            FeedWidgetSynchronizer.loadWithURLSession,
        workQueue: DispatchQueue = DispatchQueue(
            label: "HomeFeatureV2.FeedWidgetSynchronizer"
        )
    ) {
        self.store = store
        self.loadImageData = loadImageData
        self.workQueue = workQueue
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
        let post = Self.latestTodayPost(in: postsByDate)

        workQueue.async { [self] in
            store.saveUser(user)
            displayedPostIDByGroupID[groupId] = post?.postId

            guard let post else {
                // 오늘 게시물이 없으면 오늘 사진을 모두 지워 플레이스홀더를 보여 줍니다.
                reloadIfRemoved(outdatedPhotosIn: groupId)
                return
            }

            if hasPhoto(of: post, groupId: groupId) {
                reloadIfRemoved(outdatedPhotosIn: groupId)
            } else {
                // 새 사진을 저장할 때까지 기존 사진을 보여 주고, 저장한 뒤 정리합니다.
                download(post, groupId: groupId)
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

        workQueue.async { [self] in
            if displayedPostIDByGroupID[groupId] == post.postId {
                displayedPostIDByGroupID[groupId] = nil
            }
            store.deletePhoto(
                groupId: groupId,
                dateKey: Self.dateKey(of: post),
                identifier: post.postId
            )
            store.reloadWidget()
        }
    }

    /// 지금까지 요청한 작업이 끝날 때까지 기다립니다. 테스트에서 사용합니다.
    func waitUntilIdle() {
        workQueue.sync {}
    }
}

private extension FeedWidgetSynchronizer {
    func download(
        _ post: Post,
        groupId: String
    ) {
        guard
            let imageURL = URL(string: post.imageURL),
            downloadingPostIDs.insert(post.postId).inserted
        else {
            return
        }

        loadImageData(imageURL) { [weak self] data in
            self?.workQueue.async {
                self?.finishDownload(
                    of: post,
                    groupId: groupId,
                    data: data
                )
            }
        }
    }

    func finishDownload(
        of post: Post,
        groupId: String,
        data: Data?
    ) {
        downloadingPostIDs.remove(post.postId)
        guard
            let data,
            displayedPostIDByGroupID[groupId] == post.postId,
            !hasPhoto(of: post, groupId: groupId)
        else {
            return
        }

        do {
            try store.savePhoto(
                data: data,
                groupId: groupId,
                identifier: post.postId
            )
            removeOutdatedPhotos(in: groupId)
            store.reloadWidget()
        } catch {
            Logger.e("FeedWidgetSynchronizer savePhoto failed: \(error)")
        }
    }

    func hasPhoto(
        of post: Post,
        groupId: String
    ) -> Bool {
        store
            .photoIdentifiers(
                groupId: groupId,
                dateKey: Self.dateKey(of: post)
            )
            .contains(post.postId)
    }

    func reloadIfRemoved(
        outdatedPhotosIn groupId: String
    ) {
        if removeOutdatedPhotos(in: groupId) {
            store.reloadWidget()
        }
    }

    /// 오늘 폴더에서 위젯에 보여야 할 게시물이 아닌 사진을 지웁니다.
    ///
    /// - Returns: 지운 사진이 있으면 `true`.
    @discardableResult
    func removeOutdatedPhotos(
        in groupId: String
    ) -> Bool {
        let todayKey = Date().widgetDateKey()
        let displayedPostID = displayedPostIDByGroupID[groupId]
        let outdatedIdentifiers = store
            .photoIdentifiers(
                groupId: groupId,
                dateKey: todayKey
            )
            .filter { $0 != displayedPostID }

        outdatedIdentifiers.forEach {
            store.deletePhoto(
                groupId: groupId,
                dateKey: todayKey,
                identifier: $0
            )
        }
        return !outdatedIdentifiers.isEmpty
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

    /// 파일 이름 앞의 저장 시각(`yyyy-MM-dd-HH-mm-ss-`) 길이입니다.
    private static let timestampPrefixLength = 20

    func saveUser(_ user: User) {
        WidgetSessionStore.saveUser(user)
    }

    /// `WidgetPhotoStore`가 저장한 `<저장 시각>-<식별자>.jpg` 파일에서 식별자를 읽습니다.
    func photoIdentifiers(
        groupId: String,
        dateKey: String
    ) -> [String] {
        guard
            let folder = WidgetPaths.photosFolder(
                groupId: groupId,
                dateKey: dateKey
            ),
            let files = try? FileManager.default.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
        else {
            return []
        }
        return files
            .map(\.lastPathComponent)
            .filter {
                $0.hasSuffix(".jpg")
                    && $0.count > Self.timestampPrefixLength + 4
            }
            .map {
                String(
                    $0.dropFirst(Self.timestampPrefixLength)
                        .dropLast(4)
                )
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

    /// 작업 큐에서 불리므로 메인 스레드에서 요청합니다.
    func reloadWidget() {
        DispatchQueue.main.async {
            WidgetCenter.shared.reloadTimelines(
                ofKind: Self.photoWidgetKind
            )
        }
    }
}
