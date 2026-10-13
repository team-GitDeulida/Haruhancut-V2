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

    func test_fetchedValues_sendsOnce_whenServerValueEqualsCache() {
        cache.value = 10
        let recorder = recordValues(makeSUT().fetch().fetchedValues())

        remote.succeed(10)

        XCTAssertEqual(recorder.values, [10])
        XCTAssertTrue(recorder.isCompleted)
    }

    // MARK: - observe

    func test_observe_sendsStoredValueAndChanges_withoutDuplicates() {
        let stored = BehaviorSubject<Int?>(value: 10)
        let sut = makeSUT(observeLocal: { stored.asObservable() })
        var values: [Int?] = []
        sut.observe()
            .subscribe(onNext: { values.append($0) })
            .disposed(by: disposeBag)

        stored.onNext(10)
        stored.onNext(20)
        stored.onNext(nil)

        XCTAssertEqual(values, [10, 20, nil])
        XCTAssertEqual(remote.requestCount, 0)
    }

    func test_observe_sendsCurrentValueOnce_withoutObserveLocal() {
        cache.value = 10
        var values: [Int?] = []
        var isCompleted = false
        makeSUT().observe()
            .subscribe(
                onNext: { values.append($0) },
                onCompleted: { isCompleted = true }
            )
            .disposed(by: disposeBag)

        XCTAssertEqual(values, [10])
        XCTAssertTrue(isCompleted)
    }

    // MARK: - update

    func test_update_changesCacheFirstAndKeepsIt_whenWriteSucceeds() {
        cache.value = 10
        let write = PublishSubject<Void>()
        var result: Int?
        makeSUT()
            .update({ $0 += 1 }, remote: { _ in write.take(1).asSingle() })
            .subscribe(onSuccess: { result = $0 })
            .disposed(by: disposeBag)

        // 서버 응답 전에 캐시가 먼저 바뀝니다.
        XCTAssertEqual(cache.value, 11)

        write.onNext(())

        XCTAssertEqual(result, 11)
        XCTAssertEqual(cache.updatedValues, [11])
    }

    func test_update_restoresCache_whenWriteFails() {
        cache.value = 10
        var error: Error?
        makeSUT()
            .update({ $0 += 1 }, remote: { _ in .error(TestError.remote) })
            .subscribe(onFailure: { error = $0 })
            .disposed(by: disposeBag)

        XCTAssertEqual(cache.value, 10)
        XCTAssertEqual(cache.updatedValues, [11, 10])
        XCTAssertEqual(error as? TestError, .remote)
    }

    func test_update_asksServerInsteadOfRestoring_whenCacheChangedBeforeFailure() {
        cache.value = 10
        let write = PublishSubject<Void>()
        var error: Error?
        makeSUT()
            .update({ $0 += 1 }, remote: { _ in write.take(1).asSingle() })
            .subscribe(onFailure: { error = $0 })
            .disposed(by: disposeBag)

        // 쓰기가 끝나기 전에 다른 변경(서버 값, 다른 쓰기)이 저장됐습니다.
        cache.update(50)
        write.onError(TestError.remote)

        // 원래 값(10)으로 덮어쓰지 않고 서버에 다시 묻습니다.
        XCTAssertEqual(cache.value, 50)
        XCTAssertEqual(remote.requestCount, 1)
        XCTAssertNil(error)

        remote.succeed(60)

        XCTAssertEqual(cache.value, 60)
        XCTAssertEqual(cache.updatedValues, [11, 50, 60])
        XCTAssertEqual(error as? TestError, .remote)
    }

    func test_update_doesNotRestoreCache_whenTargetChangedBeforeFailure() {
        cache.value = 10
        let write = PublishSubject<Void>()
        makeSUT()
            .update({ $0 += 1 }, remote: { _ in write.take(1).asSingle() })
            .subscribe()
            .disposed(by: disposeBag)

        isCurrent = false
        write.onError(TestError.remote)

        XCTAssertEqual(cache.updatedValues, [11])
    }

    func test_update_failsWithMissingLocal_whenCacheIsEmpty() {
        var error: Error?
        makeSUT()
            .update({ $0 += 1 }, remote: { _ in .just(()) })
            .subscribe(onFailure: { error = $0 })
            .disposed(by: disposeBag)

        XCTAssertEqual(error as? FetchError, .missingLocal)
        XCTAssertTrue(cache.updatedValues.isEmpty)
    }

    // MARK: - timeout

    func test_timeout_sendsFailureWithCache_whenServerDoesNotRespond() {
        cache.value = 10
        let scheduler = HistoricalScheduler()
        let recorder = record(
            makeSUT()
                .timeout(.seconds(5), scheduler: scheduler)
                .fetch()
        )

        scheduler.advanceTo(Date(timeIntervalSince1970: 4))
        XCTAssertEqual(recorder.steps, [.loading(10)])

        scheduler.advanceTo(Date(timeIntervalSince1970: 5))
        XCTAssertEqual(recorder.steps, [.loading(10), .failure(10)])
        XCTAssertEqual(recorder.failureError as? FetchError, .timeout)
        XCTAssertEqual(cache.value, 10)
    }

    // MARK: - cleanUpNotFound

    func test_cleanUpNotFound_sendsNotFoundAfterCleanUpCompletes() {
        cache.value = 10
        let cleanUp = PublishSubject<Never>()
        let recorder = record(
            makeSUT(cleanUpNotFound: { cleanUp.asCompletable() }).fetch()
        )

        remote.succeed(nil)
        // 캐시는 바로 지우고, 뒷정리가 끝날 때까지 없음을 보내지 않습니다.
        XCTAssertNil(cache.value)
        XCTAssertEqual(recorder.steps, [.loading(10)])

        cleanUp.onCompleted()
        XCTAssertEqual(recorder.steps, [.loading(10), .notFound])
    }

    func test_cleanUpNotFound_sendsFailure_whenCleanUpFails() {
        cache.value = 10
        let recorder = record(
            makeSUT(cleanUpNotFound: { .error(TestError.remote) }).fetch()
        )

        remote.succeed(nil)

        XCTAssertEqual(recorder.steps, [.loading(10), .failure(nil)])
        XCTAssertEqual(recorder.failureError as? TestError, .remote)
    }

    // MARK: - sharing

    func test_sharing_sendsOneRequest_whenFetchedTwiceAtTheSameTime() {
        cache.value = 10
        let requests = FetchRequests<Int>()
        let first = record(makeSUT().sharing(requests, key: "group").fetch())
        let second = record(makeSUT().sharing(requests, key: "group").fetch())

        remote.succeed(20)

        XCTAssertEqual(remote.requestCount, 1)
        XCTAssertEqual(first.steps, [.loading(10), .success(20)])
        XCTAssertEqual(second.steps, [.loading(10), .success(20)])
    }

    func test_sharing_sendsNewRequest_afterPreviousRequestFinished() {
        let requests = FetchRequests<Int>()
        _ = record(makeSUT().sharing(requests, key: "group").refresh())
        remote.succeed(20)

        _ = record(makeSUT().sharing(requests, key: "group").refresh())

        XCTAssertEqual(remote.requestCount, 2)
    }

    func test_sharing_skipsServer_whenValueWasReceivedWithinMaxAge() {
        var now = Date(timeIntervalSince1970: 0)
        let requests = FetchRequests<Int>(maxAge: 10, now: { now })
        _ = record(makeSUT().sharing(requests, key: "group").fetch())
        remote.succeed(20)

        now = Date(timeIntervalSince1970: 9)
        let recorder = record(makeSUT().sharing(requests, key: "group").fetch())

        XCTAssertEqual(remote.requestCount, 1)
        XCTAssertEqual(recorder.steps, [.loading(20), .success(20)])
        XCTAssertTrue(recorder.isCompleted)
    }

    func test_sharing_asksServerAgain_afterMaxAge() {
        var now = Date(timeIntervalSince1970: 0)
        let requests = FetchRequests<Int>(maxAge: 10, now: { now })
        _ = record(makeSUT().sharing(requests, key: "group").fetch())
        remote.succeed(20)

        now = Date(timeIntervalSince1970: 10)
        _ = record(makeSUT().sharing(requests, key: "group").fetch())

        XCTAssertEqual(remote.requestCount, 2)
    }

    func test_sharing_refreshAlwaysAsksServer_evenWithinMaxAge() {
        let requests = FetchRequests<Int>(maxAge: 10)
        _ = record(makeSUT().sharing(requests, key: "group").fetch())
        remote.succeed(20)

        _ = record(makeSUT().sharing(requests, key: "group").refresh())

        XCTAssertEqual(remote.requestCount, 2)
    }

    func test_sharing_asksServerAgain_afterInvalidate() {
        let requests = FetchRequests<Int>(maxAge: 10)
        _ = record(makeSUT().sharing(requests, key: "group").fetch())
        remote.succeed(20)

        requests.invalidate(key: "group")
        _ = record(makeSUT().sharing(requests, key: "group").fetch())

        XCTAssertEqual(remote.requestCount, 2)
    }

    func test_sharing_dropsServerValue_thatStartedBeforeWrite() {
        cache.value = 10
        let requests = FetchRequests<Int>()
        let reading = record(makeSUT().sharing(requests, key: "group").fetch())
        let write = PublishSubject<Void>()
        makeSUT().sharing(requests, key: "group")
            .update({ $0 += 1 }, remote: { _ in write.take(1).asSingle() })
            .subscribe()
            .disposed(by: disposeBag)

        // 쓰기 전에 시작된 읽기가 예전 서버 값을 받습니다.
        remote.succeed(5)

        XCTAssertEqual(cache.value, 11)
        XCTAssertEqual(reading.steps, [.loading(10)])
        XCTAssertTrue(reading.isCompleted)
    }

    func test_sharing_dropsServerValue_thatStartedDuringWrite() {
        cache.value = 10
        let requests = FetchRequests<Int>()
        let write = PublishSubject<Void>()
        makeSUT().sharing(requests, key: "group")
            .update({ $0 += 1 }, remote: { _ in write.take(1).asSingle() })
            .subscribe()
            .disposed(by: disposeBag)
        let reading = record(makeSUT().sharing(requests, key: "group").fetch())

        // 쓰기가 끝난 뒤에 응답이 와도, 쓰는 동안 시작된 읽기라 버립니다.
        write.onNext(())
        remote.succeed(5)

        XCTAssertEqual(cache.value, 11)
        XCTAssertEqual(reading.steps, [.loading(11)])
    }

    func test_sharing_appliesServerValue_thatStartedAfterWrite() {
        cache.value = 10
        let requests = FetchRequests<Int>()
        makeSUT().sharing(requests, key: "group")
            .update({ $0 += 1 }, remote: { _ in .just(()) })
            .subscribe()
            .disposed(by: disposeBag)

        let reading = record(makeSUT().sharing(requests, key: "group").fetch())
        remote.succeed(20)

        XCTAssertEqual(cache.value, 20)
        XCTAssertEqual(reading.steps, [.loading(11), .success(20)])
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
    func makeSUT(
        observeLocal: (() -> Observable<Int?>)? = nil,
        cleanUpNotFound: (() -> Completable)? = nil
    ) -> Fetcher<Int> {
        let cache = cache!
        let remote = remote!
        return Fetcher(
            local: { cache.value },
            observeLocal: observeLocal,
            remote: { remote.request() },
            updateLocal: { cache.update($0) },
            removeLocal: { cache.remove() },
            cleanUpNotFound: cleanUpNotFound,
            isCurrent: { [weak self] in self?.isCurrent ?? false }
        )
    }

    func record(_ observable: Observable<FetchResult<Int>>) -> Recorder<Step> {
        let recorder = Recorder<Step>()
        observable
            .subscribe(
                onNext: { result in
                    recorder.values.append(Step(result))
                    if case let .failure(error) = result.status {
                        recorder.failureError = error
                    }
                },
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
    /// `.failure` 단계에 담긴 에러입니다.
    var failureError: Error?
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
