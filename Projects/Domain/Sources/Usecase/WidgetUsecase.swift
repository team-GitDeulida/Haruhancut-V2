import Core
import Foundation
import RxSwift

/// 홈 화면 위젯(`PhotoWidget`)이 읽는 저장소를 그룹의 오늘 사진과 맞춥니다.
public protocol WidgetUsecaseProtocol {
    /// 위젯용 사용자를 저장하고, 위젯에 오늘 가장 최근 게시물의 사진만 남깁니다.
    ///
    /// - Parameter postsByDate: 그룹에서 불러온 날짜별 게시물.
    func synchronize(
        postsByDate: [String: [Post]]
    )

    /// 삭제한 게시물의 사진을 위젯 저장소에서 지웁니다.
    ///
    /// - Parameter post: 서버에서 삭제한 게시물.
    func removePhoto(
        of post: Post
    )
}

/// 그룹마다 위젯에 보여야 할 게시물(오늘 가장 최근 게시물)을 기억하고 저장소를 맞춥니다.
///
/// 다운로드가 끝났을 때 그 게시물이 여전히 보여야 할 게시물일 때만 저장하므로, 캐시에 남은
/// 삭제된 게시물이나 다운로드 중 삭제된 게시물이 위젯에 남지 않습니다. 상태와 저장소 작업은
/// `workQueue`에서 순서대로 처리합니다.
public final class WidgetUsecaseImpl:
    WidgetUsecaseProtocol
{
    private let repository:
        WidgetRepositoryProtocol
    private let userSession:
        UserSession
    private let workQueue:
        DispatchQueue
    private let now:
        () -> Date

    /// 그룹 ID별로 위젯에 보여야 할 게시물 ID입니다. `workQueue`에서만 접근합니다.
    private var displayedPostIdByGroupId:
        [String: String] = [:]

    /// 내려받는 중인 게시물 ID입니다. `workQueue`에서만 접근합니다.
    private var downloadingPostIds:
        Set<String> = []

    /// - Parameters:
    ///   - repository: 위젯 저장소.
    ///   - userSession: 위젯이 그룹을 찾을 때 쓰는 현재 사용자 세션.
    ///   - workQueue: 상태와 저장소 작업을 순서대로 처리할 직렬 큐.
    ///   - now: 오늘 날짜를 정하는 현재 시각.
    public init(
        repository:
            WidgetRepositoryProtocol,
        userSession:
            UserSession,
        workQueue:
            DispatchQueue = DispatchQueue(
                label: "Domain.WidgetUsecase"
            ),
        now:
            @escaping () -> Date = Date.init
    ) {
        self.repository = repository
        self.userSession = userSession
        self.workQueue = workQueue
        self.now = now
    }

    public func synchronize(
        postsByDate: [String: [Post]]
    ) {
        guard
            let user =
                userSession.session,
            let groupId =
                user.groupId
        else {
            return
        }
        let post = Self.latestTodayPost(
            in: postsByDate,
            now: now()
        )

        workQueue.async { [weak self] in
            guard let self = self else { return }
            self.repository.saveUser(user)
            self.displayedPostIdByGroupId[groupId] =
                post?.postId

            guard let post else {
                // 오늘 게시물이 없으면 오늘 사진을 모두 지워 플레이스홀더를 보여 줍니다.
                self.reloadIfRemoved(
                    outdatedPhotosIn: groupId
                )
                return
            }

            if self.hasPhoto(
                of: post,
                groupId: groupId
            ) {
                self.reloadIfRemoved(
                    outdatedPhotosIn: groupId
                )
            } else {
                // 새 사진을 저장할 때까지 기존 사진을 보여 주고, 저장한 뒤 정리합니다.
                self.download(
                    post,
                    groupId: groupId
                )
            }
        }
    }

    public func removePhoto(
        of post: Post
    ) {
        guard
            let groupId =
                userSession.session?.groupId
        else {
            return
        }

        workQueue.async { [weak self] in
            guard let self = self else { return }
            if self.displayedPostIdByGroupId[groupId]
                == post.postId
            {
                self.displayedPostIdByGroupId[groupId] =
                    nil
            }
            self.repository.deletePhoto(
                groupId: groupId,
                date: post.createdAt,
                identifier: post.postId
            )
            self.repository.reloadWidget()
        }
    }

    /// 지금까지 요청한 작업이 끝날 때까지 기다립니다. 테스트에서 사용합니다.
    func waitUntilIdle() {
        workQueue.sync {}
    }
}

private extension WidgetUsecaseImpl {
    func download(
        _ post: Post,
        groupId: String
    ) {
        guard
            let imageURL =
                URL(string: post.imageURL),
            downloadingPostIds
                .insert(post.postId)
                .inserted
        else {
            return
        }

        _ = repository
            .fetchImageData(from: imageURL)
            .map { Optional($0) }
            .catchAndReturn(nil)
            .subscribe(onSuccess: {
                [weak self] data in
                guard let self = self else { return }
                self.workQueue.async {
                    self.finishDownload(
                        of: post,
                        groupId: groupId,
                        data: data
                    )
                }
            })
    }

    func finishDownload(
        of post: Post,
        groupId: String,
        data: Data?
    ) {
        downloadingPostIds.remove(post.postId)
        // 저장소는 저장하는 시각의 날짜 폴더에 쓰므로, 자정을 넘겨 끝난 다운로드는 저장하지 않습니다.
        guard
            let data,
            displayedPostIdByGroupId[groupId]
                == post.postId,
            Calendar.current.isDate(
                post.createdAt,
                inSameDayAs: now()
            ),
            !hasPhoto(
                of: post,
                groupId: groupId
            )
        else {
            return
        }

        do {
            try repository.savePhoto(
                data,
                groupId: groupId,
                identifier: post.postId
            )
            removeOutdatedPhotos(in: groupId)
            repository.reloadWidget()
        } catch {
            Logger.e(
                "WidgetUsecase savePhoto failed: \(error)"
            )
        }
    }

    func hasPhoto(
        of post: Post,
        groupId: String
    ) -> Bool {
        repository
            .photoIdentifiers(
                groupId: groupId,
                date: post.createdAt
            )
            .contains(post.postId)
    }

    func reloadIfRemoved(
        outdatedPhotosIn groupId: String
    ) {
        if removeOutdatedPhotos(in: groupId) {
            repository.reloadWidget()
        }
    }

    /// 오늘 폴더에서 위젯에 보여야 할 게시물이 아닌 사진을 지웁니다.
    ///
    /// - Returns: 지운 사진이 있으면 `true`.
    @discardableResult
    func removeOutdatedPhotos(
        in groupId: String
    ) -> Bool {
        let today = now()
        let displayedPostId =
            displayedPostIdByGroupId[groupId]
        let outdatedIdentifiers = repository
            .photoIdentifiers(
                groupId: groupId,
                date: today
            )
            .filter { $0 != displayedPostId }

        outdatedIdentifiers.forEach {
            repository.deletePhoto(
                groupId: groupId,
                date: today,
                identifier: $0
            )
        }
        return !outdatedIdentifiers.isEmpty
    }
}

extension WidgetUsecaseImpl {
    /// 오늘 올라온 게시물 중 가장 최근 게시물을 찾습니다.
    static func latestTodayPost(
        in postsByDate: [String: [Post]],
        now: Date
    ) -> Post? {
        postsByDate.values
            .flatMap { $0 }
            .filter {
                Calendar.current.isDate(
                    $0.createdAt,
                    inSameDayAs: now
                )
            }
            .max { $0.createdAt < $1.createdAt }
    }
}
