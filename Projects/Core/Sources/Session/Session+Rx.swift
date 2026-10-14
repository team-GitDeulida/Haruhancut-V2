//
//  Session+Rx.swift
//  Core
//
//  Created by 김동현 on 10/13/26.
//

import RxSwift

public extension SessionContext {
    /// 지금 값을 먼저 보내고, 값이 바뀔 때마다 보내는 스트림을 만듭니다.
    ///
    /// 값을 지우면 `nil`을 보냅니다. 끝나지 않는 스트림이므로 화면이 사라질 때 구독을 해제합니다.
    /// 구독을 해제하면 관찰도 끝납니다.
    func asObservable() -> Observable<Model?> {
        Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }

            let id = self.bind { model in
                observer.onNext(model)
            }
            return Disposables.create { [weak self] in
                self?.removeObserver(id)
            }
        }
    }
}
