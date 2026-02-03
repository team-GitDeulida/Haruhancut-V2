//
//  RxSwiftObservable.swift
//  RxLab
//
//  Created by 김동현 on 1/13/26.
//
// https://velog.io/@maddie/iOS-RxSwift4-연산자-사전
// https://babbab2.tistory.com/185

/*
 Observable : 흘려보내기만 한다 (읽기 전용)
 Subject    : 밖에서 값을 밀어 넣을 수 있다
 Relay      : Subject인데 절대 죽지 않는다
 
 
 MARK: Observable
 ─────────────────────────────────────
 MARK: Observable은 “값이 시간에 따라 흘러나오는 읽기 전용 스트림”이다.

 - Rx의 가장 기본이 되는 타입
 - 모든 Rx 타입의 출발점
 - 값은 내부 로직에서만 생성되며
   외부에서 직접 밀어 넣을 수는 없다

 개념적으로
 - 생산자 (Producer)
 - 값이 흘러가는 파이프
 
 역할
 ─────────────────────────────────────
 - 값을 방출(onNext)하는 스트림 정의
 - 비동기 이벤트를 시간 축으로 표현
 - map, filter, flatMap 등으로 값 변환

 Observable은
 ❌ 값을 저장하지 않는다
 ❌ 상태를 보장하지 않는다
 ⭕️ 그저 "흘려보낸다"
 
 특징
 ─────────────────────────────────────
 - lazy
   → subscribe 되기 전까지 실행되지 않음
 - cold observable (기본)
   → 구독 시마다 새로 실행
 - 다수의 연산자(operator)로 변환 가능

 Observable은
 - 상태 관리 ❌
 - UI 직접 바인딩 ❌
 - 비즈니스 로직 ⭕️
 
 스레드
 ─────────────────────────────────────
 - ❌ 스레드 보장 없음
 - 기본적으로 "현재 실행 중인 스레드"에서 동작

 스레드 제어는 명시적으로 해야 함
 - subscribe(on:)  → 작업 시작 스레드
 - observe(on:)    → 값 소비 스레드

 예)
 observable
     .subscribe(on: backgroundScheduler)
     .observe(on: MainScheduler.instance)
 
 에러
  ─────────────────────────────────────
  - ⭕️ 에러 방출 가능 (onError)
  - 에러 발생 시 스트림 즉시 종료
  - 이후 onNext는 전달되지 않음

  에러 제어 방법
  - catchError
  - retry
  - materialize

  Observable은
  "실패할 수 있는 스트림"을 표현하는 데 적합
 
 언제 사용하는가
 ─────────────────────────────────────
 - 네트워크 요청
 - 파일 IO
 - 비즈니스 로직 처리
 - 데이터 가공 / 변환
 - 상태가 아닌 "과정"을 표현할 때

 예)
 - API 요청 결과
 - 계산 로직
 - 데이터 파이프라인
 
 한 줄 요약
 ─────────────────────────────────────
 ❝ Observable은 값을 저장하지 않고,
    시간에 따라 흘려보내는 읽기 전용 스트림이다 ❞
 */


import Foundation
import RxSwift

enum RxExample {
    case just
    case of
    case from
    case from2
    case create
    
    case subscribe
    case bind
    
    case publish
    case behavior
    case replay
    
    static let current: RxExample = .replay
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
    case .bind:
        bind()
    case .publish:
        subject_publish()
    case .behavior:
        subject_behavior()
    case .replay:
        subject_replay()
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

