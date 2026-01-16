//
//  RxSwiftObservable.swift
//  RxLab
//
//  Created by 김동현 on 1/13/26.
//

import Foundation
import RxSwift

enum RxExample {
    case just
    case of
    case from
    case from2
    case create
    
    case subscribe
    
    static let current: RxExample = .subscribe
}

func run(_ example: RxExample) {
    switch example {
    case .just:
        observable_just()
    case .of:
        observable_of()
    case .from:
        observable_from()
    case .from2:
        observable_from_filter_map()
    case .create:
        observable_create()
        
    case .subscribe:
        subscribe()
    }
}

// Runner
func runner(description: String, action: () -> Void) {
    print("\n--- \(description) ---")
    action()
}

func observable_just() {
    /**
     Observable.just()
     오직 하나의 item을 방출하는 Sequence 생성
     (배열을 넣으면 배열 하나를 item으로 방출)
     
     emit one
     → onNext 호출
     → print(one)
     */
    
    runner(description: "Observable.just()") {
        let disposeBag = DisposeBag()
        let (one, two, three) = (1, 2, 3)
    
        /**
         1. 단일 값을 방출하는 Observable 생성
         - 구독 전까지는 실행되지 않는다
         - 값 하나를 흘러보낼 준비가 된 통로
         */
        let observable = Observable<[Int]>.just([one, two, three])
        
        /**
         2. Observable을 구독한다
         - 구독 시 Observable이 실행되며 item을 방출한다
         - 방출된 item을 onNext로 전달
         */
        observable.subscribe(onNext: {
            print("emit: \($0)")
        })
        /**
         3. 구독으로 생성된 리소스를 위한 코드
         - 메모리 누수 방지를 위한 코드
         - dispose할 객체들을 담는 가방(여러가지 Observable객체들을 이 가방에 담아서 dispose할 수 있다)
         - disposeBag이 해제되면 구독도 함꼐 해제됨
         - Observable.just는 즉시 완료되므로 실제로 dispose가 의미는 없지만 패턴상 항상 붙이는게 정석
         **/
        .disposed(by: disposeBag)
    }
}

func observable_of() {
    /**
     타입 추론을 이용하여 Sequence를 생성
     - 여러 개의 값을 “순서대로 하나씩 방출”하고 싶을 때 사용
     */
    runner(description: "Observable.of()") {
        let disposeBag = DisposeBag()
        let (one, two, three) = (1, 2, 3)
        let observable = Observable.of(one, two, three)
        
        observable.subscribe(onNext: {
            print("emit: \($0)")
        })
        .disposed(by: disposeBag)
    }
}

func observable_from() {
    /**
     arrray 타입만 처리하여 각 요소들을 하나씩 emit 가능
     */
    runner(description: "Observable.from()") {
        let disposeBag = DisposeBag()
        let arr = [1, 2, 3, 4, 5]
        let observable = Observable.from(arr)
        
        observable.subscribe(onNext: {
            print("emit: \($0)")
        })
        .disposed(by: disposeBag)
    }
}

func observable_from_filter_map() {
    runner(description: "observable_from_filter_map") {
        let disposeBag = DisposeBag()
        let arr = [1, 2, 3, 4, 5]
        let observable = Observable.from(arr)
        
        observable
            .filter { $0.isMultiple(of: 2) } // 짝수만 필터링
            .map { String($0) }              // 문자열로 반환
            .subscribe(onNext: { str in
                print(str)
            })
            .disposed(by: disposeBag)
    }
}

func observable_create() {
    /**
     클로저 형식이며 다양한 값(onNext, onCompleted)를 생성할 수 있음
     - 파라미타로 Observer를 매개변수로 받는 클로저를 전달받는 Observable Sequence를 생성하다
     - 매개변수로 받은 Observer의 onNext, onCompleted, onError메서드를 직접 호출 가능
     - 클로저가 끝나기 전에 반드시 onCompleted이나 onError를 정확히 1번 호출해야한다
     - 그 이후로는 Observer의 다른 어떤 메서드도 호출해선 안된다
     => 언제, 어떤 값을, 어떤 순서로 방출할지 내가 직접 정하는 로우레벨 Observable
     */
    let disposeBag = DisposeBag()
    let observable = Observable<String>.create { observer -> Disposable in
        observer.onNext("첫 번째 방출")
        observer.onNext("두 번째 방출")
        observer.onCompleted()
        observer.onNext("세 번째 방출")
        return Disposables.create()
    }
    
    observable.subscribe(
        onNext: { value in
            print("emit:", value)
        },
        onError: { error in
            print("error:", error)
        },
        onCompleted: {
            print("completed")
        },
        onDisposed: {
            print("disposed")
        }
    )
    .disposed(by: disposeBag)
}

