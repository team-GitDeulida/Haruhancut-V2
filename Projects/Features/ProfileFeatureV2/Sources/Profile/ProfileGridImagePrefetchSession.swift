import Kingfisher
import UIKit

/// 프로필 그리드에서 사용할 다운샘플 이미지 요청입니다.
public struct ProfileGridImagePrefetchRequest: Hashable {
    public let postID: String
    public let imageURL: URL

    public init(
        postID: String,
        imageURL: URL
    ) {
        self.postID = postID
        self.imageURL = imageURL
    }
}

/// 그리드 프리패치 요청을 작은 순차 배치로 조절합니다.
///
/// `ImagePrefetcher`는 인스턴스별로 동시 다운로드 제한을 관리하므로,
/// 게시물마다 인스턴스를 만들면 전체 요청 수를 제한할 수 없습니다.
/// 이 큐는 화면마다 하나만 두고, 가까운 후보를 묶어 순서대로 처리합니다.
final class ProfileGridImagePrefetchQueue {
    private let batchSize: Int
    private var pendingRequests: [ProfileGridImagePrefetchRequest] = []
    private var activePostIDs: Set<String> = []

    init(
        batchSize: Int = 6
    ) {
        self.batchSize = max(batchSize, 1)
    }

    var hasActiveBatch: Bool {
        !activePostIDs.isEmpty
    }

    func enqueue(
        _ requests: [ProfileGridImagePrefetchRequest]
    ) {
        let knownPostIDs =
            activePostIDs.union(
                Set(
                    pendingRequests.map(\.postID)
                )
            )
        let newRequests = requests.filter {
            !knownPostIDs.contains($0.postID)
        }
        pendingRequests.append(
            contentsOf: newRequests
        )
    }

    func nextBatch() -> [ProfileGridImagePrefetchRequest] {
        guard !hasActiveBatch,
              !pendingRequests.isEmpty
        else {
            return []
        }

        let batch = Array(
            pendingRequests.prefix(batchSize)
        )
        pendingRequests.removeFirst(
            batch.count
        )
        activePostIDs = Set(
            batch.map(\.postID)
        )
        return batch
    }

    /// - Returns: 현재 실행 중인 배치에 계속 유지할 요청이 남았는지 여부입니다.
    func cancel(
        postIDs: Set<String>
    ) -> Bool {
        pendingRequests.removeAll {
            postIDs.contains($0.postID)
        }
        activePostIDs.subtract(
            postIDs
        )
        return !activePostIDs.isEmpty
    }

    func finishActiveBatch() {
        activePostIDs.removeAll()
    }

    func reset() {
        pendingRequests.removeAll()
        activePostIDs.removeAll()
    }
}

/// 프로필 그리드의 스크롤 기반 이미지 프리패치 세션입니다.
///
/// 셀 렌더링과 같은 다운샘플러 및 백그라운드 디코더를 사용하고,
/// 원본은 디스크 캐시에 보관해 상세 화면에서 다시 사용할 수 있게 합니다.
public final class ProfileGridImagePrefetchSession {
    private let queue: ProfileGridImagePrefetchQueue
    private let maxConcurrentDownloads: Int
    private var prefetcher: ImagePrefetcher?
    private var activeBatchID: UUID?
    private var targetWidth: CGFloat?

    public init(
        batchSize: Int = 6,
        maxConcurrentDownloads: Int = 6
    ) {
        queue = ProfileGridImagePrefetchQueue(
            batchSize: batchSize
        )
        self.maxConcurrentDownloads = max(
            maxConcurrentDownloads,
            1
        )
    }

    deinit {
        stop()
    }

    /// 가까운 그리드 이미지를 프리패치 후보로 등록합니다.
    public func prefetch(
        _ requests: [ProfileGridImagePrefetchRequest],
        targetWidth: CGFloat
    ) {
        guard !requests.isEmpty else {
            return
        }

        updateTargetWidthIfNeeded(
            targetWidth
        )
        queue.enqueue(requests)
        startNextBatchIfNeeded()
    }

    /// 더 이상 필요하지 않은 이미지 후보를 제거합니다.
    public func cancelPrefetching(
        postIDs: [String]
    ) {
        guard !postIDs.isEmpty else {
            return
        }

        let hasActiveRequests = queue.cancel(
            postIDs: Set(postIDs)
        )
        guard !hasActiveRequests else {
            return
        }

        cancelActiveBatch()
        startNextBatchIfNeeded()
    }

    /// 화면을 벗어나거나 캐시를 비울 때 실행 중인 프리패치를 정리합니다.
    public func stop() {
        prefetcher?.stop()
        prefetcher = nil
        activeBatchID = nil
        queue.reset()
    }

    private func updateTargetWidthIfNeeded(
        _ newTargetWidth: CGFloat
    ) {
        let normalizedWidth = max(
            newTargetWidth,
            1
        )
        guard targetWidth != normalizedWidth else {
            return
        }

        stop()
        targetWidth = normalizedWidth
    }

    private func startNextBatchIfNeeded() {
        guard prefetcher == nil,
              let targetWidth
        else {
            return
        }

        let batch = queue.nextBatch()
        guard !batch.isEmpty else {
            return
        }

        let batchID = UUID()
        let prefetcher = ImagePrefetcher(
            urls: batch.map(\.imageURL),
            options: ProfileGridImageRequest.prefetchOptions(
                targetWidth: targetWidth
            ),
            completionHandler: {
                [weak self] _, _, _ in
                DispatchQueue.main.async {
                    self?.finishBatch(
                        identifiedBy: batchID
                    )
                }
            }
        )
        prefetcher.maxConcurrentDownloads =
            maxConcurrentDownloads
        activeBatchID = batchID
        self.prefetcher = prefetcher
        prefetcher.start()
    }

    private func cancelActiveBatch() {
        prefetcher?.stop()
        prefetcher = nil
        activeBatchID = nil
        queue.finishActiveBatch()
    }

    private func finishBatch(
        identifiedBy batchID: UUID
    ) {
        guard activeBatchID == batchID else {
            return
        }

        prefetcher = nil
        activeBatchID = nil
        queue.finishActiveBatch()
        startNextBatchIfNeeded()
    }
}
