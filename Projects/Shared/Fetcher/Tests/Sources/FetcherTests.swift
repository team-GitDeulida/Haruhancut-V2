//
//  FetcherTests.swift
//  FetcherTests
//
//  Created by 김동현 on 8/22/26.
//

import XCTest
import RxSwift
@testable import Fetcher

final class FetcherTests: XCTestCase {
    
    func test_fetch를_호출하면_현재_로컬값을_loading으로_전달한다() {
        // Given
        let localStorage = TestLocalStorage(initialValue: 10)
        let remoteStorage = PublishSubject<Int>()
        var outputs: [ReceivedOutput<Int>] = []
        
        let sut = makeSUT(
            localStorage: localStorage,
            remoteStorage: remoteStorage
        )
        
        // When
        let disposable = sut.fetch { status, value in
            outputs.append(
                ReceivedOutput(
                    status: status,
                    value: value
                )
            )
        }
        defer { disposable.dispose() }

        // Then
        XCTAssertEqual(outputs.count, 1)
        XCTAssertEqual(outputs[0].value, 10)
        assertLoading(outputs[0].status)
    }

    func test_원격조회에_성공하면_데이터를_로컬에_저장한다() {
        // Given
        let localStorage = TestLocalStorage(initialValue: 10)
        let remoteStorage = PublishSubject<Int>()

        let sut = makeSUT(
            localStorage: localStorage,
            remoteStorage: remoteStorage
        )

        // When
        let disposable = sut.fetch { _, _ in }
        defer { disposable.dispose() }

        remoteStorage.onNext(20)
        remoteStorage.onCompleted()

        // Then
        XCTAssertEqual(localStorage.currentValue, 20)
        XCTAssertEqual(localStorage.updatedValues, [20])
    }

    func test_원격조회에_성공하면_갱신된_로컬값을_success로_전달한다() {
        // Given
        let localStorage = TestLocalStorage(initialValue: 10)
        let remoteStorage = PublishSubject<Int>()
        var outputs: [ReceivedOutput<Int>] = []

        let sut = makeSUT(
            localStorage: localStorage,
            remoteStorage: remoteStorage
        )

        // When
        let disposable = sut.fetch { status, value in
            outputs.append(
                ReceivedOutput(
                    status: status,
                    value: value
                )
            )
        }
        defer { disposable.dispose() }

        remoteStorage.onNext(20)
        remoteStorage.onCompleted()

        // Then
        XCTAssertEqual(outputs.count, 2)
        XCTAssertEqual(outputs.map(\.value), [10, 20])

        assertLoading(outputs[0].status)
        assertSuccess(outputs[1].status)
    }

    func test_원격조회에_실패하면_기존_로컬값을_failure로_전달한다() {
        // Given
        let localStorage = TestLocalStorage(initialValue: 10)
        let remoteStorage = PublishSubject<Int>()
        var outputs: [ReceivedOutput<Int>] = []

        let sut = makeSUT(
            localStorage: localStorage,
            remoteStorage: remoteStorage
        )

        // When
        let disposable = sut.fetch { status, value in
            outputs.append(
                ReceivedOutput(
                    status: status,
                    value: value
                )
            )
        }
        defer { disposable.dispose() }

        remoteStorage.onError(TestError.remote)

        // Then
        XCTAssertEqual(outputs.count, 2)
        XCTAssertEqual(outputs.map(\.value), [10, 10])

        assertLoading(outputs[0].status)
        assertFailure(
            outputs[1].status,
            expectedError: .remote
        )
    }
    
    func test_원격조회에_실패하면_로컬데이터를_변경하지_않는다() {
        // Given
        let localStorage = TestLocalStorage(initialValue: 10)
        let remoteStorage = PublishSubject<Int>()
        
        let sut = makeSUT(
            localStorage: localStorage,
            remoteStorage: remoteStorage
        )
        
        // When
        let disposable = sut.fetch { _, _ in }
        defer { disposable.dispose() }
        
        remoteStorage.onError(TestError.remote)
        
        // Then
        XCTAssertEqual(localStorage.currentValue, 10)
        XCTAssertTrue(localStorage.updatedValues.isEmpty)
    }
    
    func test_원격조회에_성공한후_로컬데이터가_변경되면_새로운값을_success로_전달한다() {
        // Given
        let localStorage = TestLocalStorage(initialValue: 10)
        let remoteStorage = PublishSubject<Int>()
        var outputs: [ReceivedOutput<Int>] = []
        
        let sut = makeSUT(
            localStorage: localStorage,
            remoteStorage: remoteStorage
        )
        
        let disposable = sut.fetch { status, value in
            outputs.append(
                ReceivedOutput(
                    status: status,
                    value: value
                )
            )
        }
        defer { disposable.dispose() }
        
        remoteStorage.onNext(20)
        remoteStorage.onCompleted()
        
        // When
        localStorage.update(30)
        
        // Then
        XCTAssertEqual(outputs.count, 3)
        XCTAssertEqual(outputs.map(\.value), [10, 20, 30])
        
        assertLoading(outputs[0].status)
        assertSuccess(outputs[1].status)
        assertSuccess(outputs[2].status)
    }
    
    func test_dispose하면_더이상_로컬변경을_전달하지_않는다() {
        // Given
        let localStorage = TestLocalStorage(initialValue: 10)
        let remoteStorage = PublishSubject<Int>()
        var outputs: [ReceivedOutput<Int>] = []
        
        let sut = makeSUT(
            localStorage: localStorage,
            remoteStorage: remoteStorage
        )
        
        let disposable = sut.fetch { status, value in
            outputs.append(
                ReceivedOutput(
                    status: status,
                    value: value
                )
            )
        }
        
        remoteStorage.onNext(20)
        remoteStorage.onCompleted()
        
        // When
        disposable.dispose()
        localStorage.update(30)
        
        // Then
        XCTAssertEqual(outputs.count, 2)
        XCTAssertEqual(outputs.map(\.value), [10, 20])
    }
    
    func test_로컬관찰에_실패하면_현재_로컬값을_failure로_전달한다() {
        // Given
        let localStorage = TestLocalStorage(initialValue: 10)
        let remoteStorage = PublishSubject<Int>()
        var outputs: [ReceivedOutput<Int>] = []
        
        let sut = makeSUT(
            localStorage: localStorage,
            remoteStorage: remoteStorage
        )
        
        let disposable = sut.fetch { status, value in
            outputs.append(
                ReceivedOutput(
                    status: status,
                    value: value
                )
            )
        }
        defer { disposable.dispose() }
        
        remoteStorage.onNext(20)
        remoteStorage.onCompleted()
        
        // When
        localStorage.fail(with: TestError.local)
        
        // Then
        XCTAssertEqual(outputs.count, 3)
        XCTAssertEqual(outputs.map(\.value), [10, 20, 20])
        
        assertFailure(
            outputs[2].status,
            expectedError: .local
        )
    }
}

// MARK: - SUT
private extension FetcherTests {

    func makeSUT(
        localStorage: TestLocalStorage<Int>,
        remoteStorage: PublishSubject<Int>
    ) -> Fetcher<Int> {
        Fetcher(
            onLocalStorage: {
                localStorage.observe()
            },
            onRemoteStorage: {
                remoteStorage
                    .take(1)
                    .asSingle()
            },
            onLocal: {
                localStorage.currentValue
            },
            onUpdateLocal: { value in
                localStorage.update(value)
            }
        )
    }
}

// MARK: - FetchStatus 검증
private extension FetcherTests {

    func assertLoading(
        _ status: FetchStatus,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .loading = status else {
            XCTFail(
                "loading 상태를 기대했지만 \(status)를 전달받았습니다.",
                file: file,
                line: line
            )
            return
        }
    }

    func assertSuccess(
        _ status: FetchStatus,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .success = status else {
            XCTFail(
                "success 상태를 기대했지만 \(status)를 전달받았습니다.",
                file: file,
                line: line
            )
            return
        }
    }

    func assertFailure(
        _ status: FetchStatus,
        expectedError: TestError,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case let .failure(error) = status else {
            XCTFail(
                "failure 상태를 기대했지만 \(status)를 전달받았습니다.",
                file: file,
                line: line
            )
            return
        }

        guard let receivedError = error as? TestError else {
            XCTFail(
                "예상하지 못한 에러 타입입니다: \(error)",
                file: file,
                line: line
            )
            return
        }

        XCTAssertEqual(
            receivedError,
            expectedError,
            file: file,
            line: line
        )
    }
}

// MARK: - 테스트용 Local Storage
private final class TestLocalStorage<Value> {
    
    private let subject: BehaviorSubject<Value>
    private(set) var currentValue: Value
    private(set) var updatedValues: [Value] = []
    
    init(initialValue: Value) {
        self.currentValue = initialValue
        self.subject = BehaviorSubject(value: initialValue)
    }
    
    func observe() -> Observable<Value> {
        subject.asObservable()
    }

    func update(_ value: Value) {
        currentValue = value
        updatedValues.append(value)
        subject.onNext(value)
    }

    func fail(with error: Error) {
        subject.onError(error)
    }
}


// MARK: - 테스트 결과
private struct ReceivedOutput<Value> {
    let status: FetchStatus
    let value: Value
}

// MARK: - 테스트 에러
private enum TestError: Error, Equatable {
    case remote
    case local
}
