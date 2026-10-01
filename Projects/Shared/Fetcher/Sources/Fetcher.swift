//
//  Fetcher.swift
//  Fetcher
//
//  Created by 김동현 on 8/21/26.
//

/**
 Observable:
 - 0개 이상의 값을 여러 번 방출할 수 있는 스트림
 - 예: 버튼 탭, 검색어 입력, 실시간 데이터

 Single:
 - 성공 시 값 1개를 반환하거나 에러 발생
 - 예: API 조회 요청

 Completable:
 - 값은 반환하지 않고 완료 또는 에러만 전달
 - 예: 삭제, 저장, 로그아웃 요청
 */
import RxSwift

public enum FetchStatus {
    case loading
    case success
    case failure(Error)
}

public struct Fetcher<Value> {
    
    public typealias OutputHandler = (
        FetchStatus,
        Value
    ) -> Void
    
    // MARK: - Local Storage
    /// - Local Storage는 로컬 데이터 변경을 지속적으로 관찰합니다.
    public var onLocalStorage: () -> Observable<Value>
    
    // MARK: - Remote Storage
    // - Remote Storage는 한 번 요청하고 하나의 결과 또는 에러를 반환합니다.
    public var onRemoteStorage: () -> Single<Value>
    
    // 현재 로컬 값 즉시 조회
    public var onLocal: () -> Value
    
    // 서버에서 받은 값을 로컬에 저장
    public var onUpdateLocal: (Value) -> Void

    public init(
        onLocalStorage: @escaping () -> Observable<Value>,
        onRemoteStorage: @escaping () -> Single<Value>,
        onLocal: @escaping () -> Value,
        onUpdateLocal: @escaping (Value) -> Void
    ) {
        self.onLocalStorage = onLocalStorage
        self.onRemoteStorage = onRemoteStorage
        self.onLocal = onLocal
        self.onUpdateLocal = onUpdateLocal
    }
    
    public func fetch(
        onNext: @escaping OutputHandler
    ) -> Disposable {
        let localDisposable = SerialDisposable()
        let remoteDisposable = SerialDisposable()

        let disposable = Disposables.create(
            localDisposable,
            remoteDisposable
        )
        
        // 1. 현재 로컬 데이터와 함께 로딩 상태를 전달합니다.
        onNext(.loading, onLocal())
        
        // 2. Remote 데이터를 요청합니다.
        remoteDisposable.disposable = onRemoteStorage()
            .subscribe(
                onSuccess: { remoteValue in
                    // 3. Remote 데이터를 Local Storage에 저장합니다.
                    onUpdateLocal(remoteValue)
                    
                    // 4. Local Storage를 구독합니다.
                    localDisposable.disposable = onLocalStorage()
                        .subscribe(
                            onNext: { localValue in
                                onNext(.success, localValue)
                            },
                            onError: { error in
                                onNext(.failure(error),onLocal())
                            }
                        )
                },
                onFailure: { error in
                    // 5. Remote 조회에 실패하면 현재 로컬 데이터와 함께 실패 상태를 전달합니다.
                    onNext(.failure(error), onLocal())
                }
            )
        
        
        return disposable
    }
}
