//
//  FetcherTests.swift
//  CoreTests
//
//  Created by 김동현 on 10/12/26.
//

import RxSwift
import XCTest
@testable import Core

/// `Fetcher`가 서버 응답(값·없음·실패)에 따라 캐시를 다루고 조회 단계를 보내는지 확인합니다.
final class FetcherTests: XCTestCase {

    private enum TestError: Error {
        case remote
    }

    private var cache: TestCache!
    private var remote: TestRemote!
    private var disposeBag: DisposeBag!
    /// 응답이 왔을 때 아직 같은 대상인지입니다.
    private var isCurrent = true

    override func setUp() {
        super.setUp()
        cache = TestCache()
        remote = TestRemote()
        disposeBag = DisposeBag()
        isCurrent = true
    }

    override func tearDown() {
        disposeBag = nil
        remote = nil
        cache = nil
        super.tearDown()
    }

    // MARK: - fetch

    func test_fetch_sendsCachedValueAsLoadingFirst() {
        cache.value = 10

        let recorder = record(makeSUT().fetch())

        XCTAssertEqual(recorder.steps, [.loading(10)])
        XCTAssertEqual(remote.requestCount, 1)
    }

    func test_fetch_sendsNilAsLoading_whenCacheIsEmpty() {
        let recorder = record(makeSUT().fetch())

        XCTAssertEqual(recorder.steps, [.loading(nil)])
    }

    func test_fetch_savesRemoteValueAndSendsSuccess() {
        cache.value = 10
        let recorder = record(makeSUT().fetch())

        remote.succeed(20)

        XCTAssertEqual(recorder.steps, [.loading(10), .success(20)])
        XCTAssertEqual(cache.value, 20)
        XCTAssertEqual(cache.updatedValues, [20])
        XCTAssertEqual(cache.removeCount, 0)
        XCTAssertTrue(recorder.isCompleted)
    }

    func test_fetch_removesCacheAndSendsNotFound_whenRemoteHasNoData() {
        cache.value = 10
        let recorder = record(makeSUT().fetch())

        remote.succeed(nil)

        XCTAssertEqual(recorder.steps, [.loading(10), .notFound])
        XCTAssertNil(cache.value)
        XCTAssertEqual(cache.removeCount, 1)
        XCTAssertTrue(cache.updatedValues.isEmpty)
        XCTAssertTrue(recorder.isCompleted)
    }

    func test_fetch_keepsCacheAndSendsFailure_whenRemoteFails() {
        cache.value = 10
        let recorder = record(makeSUT().fetch())

        remote.fail(TestError.remote)

        XCTAssertEqual(recorder.steps, [.loading(10), .failure(10)])
        XCTAssertEqual(cache.value, 10)
        XCTAssertTrue(cache.updatedValues.isEmpty)
        XCTAssertEqual(cache.removeCount, 0)
        XCTAssertTrue(recorder.isCompleted)
        XCTAssertNil(recorder.error)
    }

    func test_fetch_readsCacheAndRequestsRemote_onlyWhenSubscribed() {
        let observable = makeSUT().fetch()
        cache.value = 30

        XCTAssertEqual(remote.requestCount, 0)

        let recorder = record(observable)

        XCTAssertEqual(recorder.steps, [.loading(30)])
        XCTAssertEqual(remote.requestCount, 1)
    }

    func test_fetch_cancelsRemoteRequest_whenDisposed() {
        cache.value = 10
        var steps: [Step] = []
        let disposable = makeSUT().fetch()
            .subscribe(onNext: { steps.append(Step($0)) })

        disposable.dispose()
        remote.succeed(20)

        XCTAssertTrue(remote.isDisposed)
        XCTAssertEqual(steps, [.loading(10)])
        XCTAssertEqual(cache.value, 10)
    }

    func test_fetch_dropsServerValue_whenTargetChangedBeforeResponse() {
        cache.value = 10
        let recorder = record(makeSUT().fetch())

        isCurrent = false
        remote.succeed(20)

        XCTAssertEqual(recorder.steps, [.loading(10)])
        XCTAssertTrue(recorder.isCompleted)
        XCTAssertEqual(cache.value, 10)
        XCTAssertTrue(cache.updatedValues.isEmpty)
    }

    func test_fetch_keepsCache_whenTargetChangedBeforeNoDataResponse() {
        cache.value = 10
        let recorder = record(makeSUT().fetch())

        isCurrent = false
        remote.succeed(nil)

        XCTAssertEqual(recorder.steps, [.loading(10)])
        XCTAssertTrue(recorder.isCompleted)
        XCTAssertEqual(cache.value, 10)
        XCTAssertEqual(cache.removeCount, 0)
    }

    func test_fetch_dropsFailure_whenTargetChangedBeforeResponse() {
        cache.value = 10
        let recorder = record(makeSUT().fetch())

        isCurrent = false
        remote.fail(TestError.remote)

        XCTAssertEqual(recorder.steps, [.loading(10)])
        XCTAssertTrue(recorder.isCompleted)
    }

    // MARK: - refresh

    func test_refresh_sendsOnlyRemoteResult() {
        cache.value = 10
        let recorder = record(makeSUT().refresh())

        XCTAssertTrue(recorder.steps.isEmpty)

        remote.succeed(20)

        XCTAssertEqual(recorder.steps, [.success(20)])
        XCTAssertEqual(cache.value, 20)
        XCTAssertTrue(recorder.isCompleted)
    }

    func test_refresh_sendsFailureWithCache_whenRemoteFails() {
        cache.value = 10
        let recorder = record(makeSUT().refresh())

        remote.fail(TestError.remote)

        XCTAssertEqual(recorder.steps, [.failure(10)])
        XCTAssertEqual(cache.value, 10)
    }

    func test_refresh_removesCache_whenRemoteHasNoData() {
        cache.value = 10
        let recorder = record(makeSUT().refresh())

        remote.succeed(nil)

        XCTAssertEqual(recorder.steps, [.notFound])
        XCTAssertNil(cache.value)
    }

    func test_refresh_sendsNothing_whenTargetChangedBeforeResponse() {
        cache.value = 10
        let recorder = record(makeSUT().refresh())

        isCurrent = false
        remote.succeed(20)

        XCTAssertTrue(recorder.steps.isEmpty)
        XCTAssertTrue(recorder.isCompleted)
        XCTAssertEqual(cache.value, 10)
    }

    // MARK: - fetchedValues

    func test_fetchedValues_sendsCachedValueThenRemoteValue() {
        cache.value = 10
        let recorder = recordValues(makeSUT().fetch().fetchedValues())

        remote.succeed(20)

        XCTAssertEqual(recorder.values, [10, 20])
        XCTAssertTrue(recorder.isCompleted)
    }

    func test_fetchedValues_skipsEmptyCache() {
        let recorder = recordValues(makeSUT().fetch().fetchedValues())

        remote.succeed(20)

        XCTAssertEqual(recorder.values, [20])
        XCTAssertTrue(recorder.isCompleted)
    }

    func test_fetchedValues_failsWithRemoteError_afterCachedValue() {
        cache.value = 10
        let recorder = recordValues(makeSUT().fetch().fetchedValues())

        remote.fail(TestError.remote)

        XCTAssertEqual(recorder.values, [10])
        XCTAssertEqual(recorder.error as? TestError, .remote)
    }

    func test_fetchedValues_failsWithNotFound_whenRemoteHasNoData() {
        cache.value = 10
        let recorder = recordValues(makeSUT().fetch().fetchedValues())

        remote.succeed(nil)

        XCTAssertEqual(recorder.values, [10])
        XCTAssertEqual(recorder.error as? FetchError, .notFound)
    }

    // MARK: - logging

    func test_logging_keepsResultsAndCacheHandling() {
        cache.value = 10
        let recorder = record(makeSUT().logging("Test").fetch())

        remote.succeed(20)

        XCTAssertEqual(recorder.steps, [.loading(10), .success(20)])
        XCTAssertEqual(cache.updatedValues, [20])
        XCTAssertTrue(recorder.isCompleted)
    }

    func test_logging_keepsNotFoundHandling() {
        cache.value = 10
        let recorder = record(makeSUT().logging("Test").refresh())

        remote.succeed(nil)

        XCTAssertEqual(recorder.steps, [.notFound])
        XCTAssertEqual(cache.removeCount, 1)
    }

    func test_logging_keepsDroppingResponse_whenTargetChanged() {
        cache.value = 10
        let recorder = record(makeSUT().logging("Test").fetch())

        isCurrent = false
        remote.succeed(20)

        XCTAssertEqual(recorder.steps, [.loading(10)])
        XCTAssertEqual(cache.value, 10)
        XCTAssertTrue(recorder.isCompleted)
    }
}

// MARK: - Helpers

private extension FetcherTests {
    func makeSUT() -> Fetcher<Int> {
        let cache = cache!
        let remote = remote!
        return Fetcher(
            local: { cache.value },
            remote: { remote.request() },
            updateLocal: { cache.update($0) },
            removeLocal: { cache.remove() },
            isCurrent: { [weak self] in self?.isCurrent ?? false }
        )
    }

    func record(_ observable: Observable<FetchResult<Int>>) -> Recorder<Step> {
        let recorder = Recorder<Step>()
        observable
            .subscribe(
                onNext: { recorder.values.append(Step($0)) },
                onError: { recorder.error = $0 },
                onCompleted: { recorder.isCompleted = true }
            )
            .disposed(by: disposeBag)
        return recorder
    }

    func recordValues(_ observable: Observable<Int>) -> Recorder<Int> {
        let recorder = Recorder<Int>()
        observable
            .subscribe(
                onNext: { recorder.values.append($0) },
                onError: { recorder.error = $0 },
                onCompleted: { recorder.isCompleted = true }
            )
            .disposed(by: disposeBag)
        return recorder
    }
}

/// 비교하기 쉽게 바꾼 조회 단계입니다.
private enum Step: Equatable {
    case loading(Int?)
    case success(Int?)
    case notFound
    case failure(Int?)

    init(_ result: FetchResult<Int>) {
        switch result.status {
        case .loading:
            self = .loading(result.value)
        case .success:
            self = .success(result.value)
        case .notFound:
            self = .notFound
        case .failure:
            self = .failure(result.value)
        }
    }
}

private extension Recorder where Element == Step {
    var steps: [Step] { values }
}

/// 구독 결과를 모읍니다.
private final class Recorder<Element> {
    var values: [Element] = []
    var error: Error?
    var isCompleted = false
}

/// 메모리 캐시입니다.
private final class TestCache {
    var value: Int?
    private(set) var updatedValues: [Int] = []
    private(set) var removeCount = 0

    func update(_ value: Int) {
        self.value = value
        updatedValues.append(value)
    }

    func remove() {
        value = nil
        removeCount += 1
    }
}

/// 응답 시점을 테스트에서 정하는 서버입니다.
private final class TestRemote {
    private(set) var requestCount = 0
    private(set) var isDisposed = false
    private var observer: ((SingleEvent<Int?>) -> Void)?

    func request() -> Single<Int?> {
        Single.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            self.requestCount += 1
            self.observer = observer
            return Disposables.create { [weak self] in
                self?.isDisposed = true
            }
        }
    }

    func succeed(_ value: Int?) {
        observer?(.success(value))
    }

    func fail(_ error: Error) {
        observer?(.failure(error))
    }
}
