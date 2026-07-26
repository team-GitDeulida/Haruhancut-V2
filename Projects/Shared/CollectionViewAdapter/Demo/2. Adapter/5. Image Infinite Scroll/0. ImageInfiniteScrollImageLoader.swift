import Foundation
import UIKit

/// 이미지 무한 스크롤 Demo에서 사용하는 메모리 캐시 기반
/// 이미지 로더입니다.
///
/// Prefetch 요청과 화면에 표시할 이미지 요청이 같은 다운로드 작업을
/// 공유합니다. Prefetch가 취소되더라도 화면에서 이미 사용 중인 요청은
/// 계속 유지합니다.
@MainActor
final class ImageInfiniteScrollImageLoader {
    /// 셀이 이미지를 가져온 경로입니다.
    enum Source {
        case memoryCache
        case network
    }

    typealias Completion = (
        _ image: UIImage?,
        _ source: Source?
    ) -> Void

    private struct InFlightRequest {
        let id: UUID
        let task: Task<Void, Never>
    }

    private let cache = NSCache<NSURL, UIImage>()
    private var inFlightRequests:
        [URL: InFlightRequest] = [:]
    private var prefetchingURLs: Set<URL> = []
    private var completions:
        [URL: [UUID: Completion]] = [:]
    private var requestURLs: [UUID: URL] = [:]

    init() {
        cache.countLimit = 80
    }

    /// 곧 화면에 표시될 이미지의 다운로드를 시작합니다.
    func prefetch(_ urls: [URL]) {
        for url in Set(urls) {
            guard cachedImage(for: url) == nil else {
                continue
            }

            prefetchingURLs.insert(url)
            startRequestIfNeeded(for: url)
        }
    }

    /// 더 이상 미리 준비할 필요가 없는 이미지 요청을 취소합니다.
    ///
    /// 같은 이미지를 화면에서 사용 중이면 다운로드를 유지합니다.
    func cancelPrefetching(_ urls: [URL]) {
        for url in Set(urls) {
            prefetchingURLs.remove(url)
            cancelRequestIfUnused(for: url)
        }
    }

    /// 화면에 표시할 이미지를 요청합니다.
    ///
    /// - Returns: 비동기 요청을 취소할 때 사용할 식별자. 메모리 캐시에서
    ///   즉시 반환한 경우에는 `nil`입니다.
    @discardableResult
    func requestImage(
        for url: URL,
        completion: @escaping Completion
    ) -> UUID? {
        if let image = cachedImage(for: url) {
            completion(image, .memoryCache)
            return nil
        }

        let requestID = UUID()
        var urlCompletions = completions[url] ?? [:]
        urlCompletions[requestID] = completion
        completions[url] = urlCompletions
        requestURLs[requestID] = url
        startRequestIfNeeded(for: url)
        return requestID
    }

    /// 화면에서 더 이상 필요하지 않은 이미지 요청을 취소합니다.
    func cancelImageRequest(_ requestID: UUID) {
        guard
            let url = requestURLs.removeValue(
                forKey: requestID
            )
        else {
            return
        }

        completions[url]?[requestID] = nil
        if completions[url]?.isEmpty == true {
            completions[url] = nil
        }
        cancelRequestIfUnused(for: url)
    }

    private func cachedImage(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    private func startRequestIfNeeded(for url: URL) {
        guard
            cachedImage(for: url) == nil,
            inFlightRequests[url] == nil
        else {
            return
        }

        let operationID = UUID()
        let task = Task { [weak self] in
            do {
                let (data, response) =
                    try await URLSession.shared.data(
                        from: url
                    )
                guard
                    !Task.isCancelled,
                    let httpResponse =
                        response as? HTTPURLResponse,
                    (200..<300).contains(
                        httpResponse.statusCode
                    ),
                    let image = UIImage(data: data)
                else {
                    self?.finishRequest(
                        for: url,
                        operationID: operationID,
                        image: nil
                    )
                    return
                }

                self?.finishRequest(
                    for: url,
                    operationID: operationID,
                    image: image
                )
            } catch {
                guard !Task.isCancelled else {
                    return
                }
                self?.finishRequest(
                    for: url,
                    operationID: operationID,
                    image: nil
                )
            }
        }

        inFlightRequests[url] = InFlightRequest(
            id: operationID,
            task: task
        )
    }

    private func finishRequest(
        for url: URL,
        operationID: UUID,
        image: UIImage?
    ) {
        guard
            inFlightRequests[url]?.id == operationID
        else {
            return
        }

        inFlightRequests[url] = nil
        prefetchingURLs.remove(url)

        if let image {
            cache.setObject(
                image,
                forKey: url as NSURL
            )
        }

        let waitingCompletions =
            completions.removeValue(forKey: url) ?? [:]
        for requestID in waitingCompletions.keys {
            requestURLs[requestID] = nil
        }

        let source: Source? =
            image == nil ? nil : .network
        for completion in waitingCompletions.values {
            completion(image, source)
        }
    }

    private func cancelRequestIfUnused(for url: URL) {
        let hasVisibleRequest =
            !(completions[url]?.isEmpty ?? true)
        guard
            !prefetchingURLs.contains(url),
            !hasVisibleRequest,
            let request =
                inFlightRequests.removeValue(forKey: url)
        else {
            return
        }

        request.task.cancel()
    }
}
