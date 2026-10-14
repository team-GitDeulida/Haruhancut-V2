//
//  NetworkReachability.swift
//  Data
//
//  Created by 김동현 on 10/14/26.
//

import Foundation
import Network
import RxCocoa
import RxSwift

/// 기기가 네트워크에 연결돼 있는지 보고, 끊겨 있으면 Firebase 쓰기를 시작하지 않게 합니다.
///
/// Firebase는 연결이 끊긴 동안 쓰기를 메모리 대기열에 넣고, 다시 연결될 때까지 완료를 알리지 않습니다.
/// 그사이 앱이 종료되면 쓰기는 사라지지만, 화면이 먼저 바꾼 값은 Session에 남습니다.
/// 그래서 네트워크가 끊겨 있으면 쓰기를 대기열에 넣지 않고 바로 `FirebaseError.offline`으로 끝냅니다.
///
/// Firebase의 `.info/connected`는 쓰지 않습니다. Realtime Database는 한동안 요청이 없으면 스스로 연결을 끊어서
/// 네트워크가 정상이어도 `false`가 되고, 다음 요청이 와야 다시 연결하기 때문입니다.
/// Storage도 같은 네트워크 상태로 판단합니다.
final class NetworkReachability {
    private struct Status {
        /// 네트워크 상태를 한 번이라도 받았는지입니다.
        var isKnown = false
        /// 네트워크에 연결돼 있는지입니다.
        var isConnected = false
        /// 더 기다리지 않고 판단할지입니다. 상태를 받았거나 `startupGrace`가 지나면 `true`입니다.
        var isSettled = false
    }

    private let status = BehaviorRelay(value: Status())
    private let disposeBag = DisposeBag()

    /// - Parameters:
    ///   - isConnected: 네트워크 상태가 바뀔 때마다 보내는 스트림.
    ///   - startupGrace: 처음 상태를 받을 때까지 기다리는 시간. 지나도 상태를 모르면 막지 않습니다.
    ///   - scheduler: `startupGrace`를 재는 스케줄러. 테스트에서 바꿉니다.
    init(
        isConnected: Observable<Bool>,
        startupGrace: RxTimeInterval = .seconds(1),
        scheduler: SchedulerType = MainScheduler.instance
    ) {
        isConnected
            .subscribe(onNext: { [weak self] isConnected in
                self?.update(isConnected: isConnected)
            })
            .disposed(by: disposeBag)

        Observable<Int>.timer(startupGrace, scheduler: scheduler)
            .subscribe(onNext: { [weak self] _ in
                self?.settle()
            })
            .disposed(by: disposeBag)
    }

    /// 연결돼 있으면 바로 완료하고, 끊겨 있으면 `FirebaseError.offline`으로 끝냅니다.
    ///
    /// 아직 상태를 받지 못했으면(만든 직후) 받거나 `startupGrace`가 지날 때까지 기다립니다.
    /// 그래도 상태를 모르면 막지 않고 완료합니다.
    func requireConnection() -> Completable {
        status
            .filter(\.isSettled)
            .take(1)
            .flatMap { status -> Observable<Never> in
                status.isKnown && !status.isConnected
                    ? .error(FirebaseError.offline)
                    : .empty()
            }
            .asCompletable()
    }
}

extension NetworkReachability {
    /// 기기의 네트워크 상태(`NWPathMonitor`)를 보는 인스턴스입니다. 처음 쓸 때 만들어 감시를 시작합니다.
    static let shared = NetworkReachability(
        isConnected: Observable.create { observer in
            let monitor = NWPathMonitor()
            monitor.pathUpdateHandler = { path in
                observer.onNext(isConnected(path.status))
            }
            monitor.start(queue: .main)
            return Disposables.create {
                monitor.cancel()
            }
        }
    )
}

extension NetworkReachability {
    /// 네트워크 상태를 연결 여부로 바꿉니다.
    ///
    /// 연결할 수 있는 경로가 없을 때(`.unsatisfied`)만 끊긴 것으로 봅니다.
    /// `.requiresConnection`은 주문형 VPN처럼 요청이 오면 연결을 맺는 상태라 막지 않습니다.
    static func isConnected(_ status: NWPath.Status) -> Bool {
        status != .unsatisfied
    }
}

private extension NetworkReachability {
    func update(isConnected: Bool) {
        var status = status.value
        status.isKnown = true
        status.isConnected = isConnected
        status.isSettled = true
        self.status.accept(status)
    }

    func settle() {
        var status = status.value
        status.isSettled = true
        self.status.accept(status)
    }
}
