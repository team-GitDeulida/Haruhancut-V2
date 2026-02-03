//
//  subscribe-bind-drive.swift
//  RxLabDemo
//
//  Created by 김동현 on 1/16/26.
//

import Foundation
import RxSwift
import RxCocoa

/*
 MARK: 이 스트림은 실패할 수 있으므로 스레드와 에러 처리까지 포함해 생명주기 전부를 내가 직접 책임지겠다
 https://green1229.tistory.com/549
 subscribe(대상: Observable)
 ─────────────────────────────────────
 역할
 - Observable이 방출하는 이벤트를 직접 받는다
 - onNext / onError / onCompleted 를 모두 처리할 수 있는
   가장 로우레벨 구독 방식

 특징
 - 모든 Observable에서 사용 가능
 - 에러 처리를 반드시 직접 해야 함
 - 스레드 보장 ❌ (기본적으로 현재 스레드에서 동작)
 - 자유도가 높지만 실수하기 쉬움

 스레드
 - ❌ 기본적으로 스레드 보장 없음
 - UI 작업 시 observe(on: MainScheduler.instance) 직접 지정 필요

 에러
 - ⭕️ onError로 직접 처리 가능
 - 에러 발생 시 스트림이 종료됨
 - retry, catchError 등으로 제어 가능

 언제 사용하는가
 - 네트워크 요청, 파일 IO 등 비즈니스 로직
 - 값 가공, 분기 처리, 디버깅
 - "이 스트림의 생명주기는 내가 책임진다"는 경우

 한 줄 요약
 - ❝ 스레드도, 에러도 내가 전부 책임진다 ❞
 */

func subscribe() {
    runner(description: "subscribe") {
        let disposeBag = DisposeBag()
        let observable = Observable.of(1, 2, 3)
        
        observable
            .observe(on: MainScheduler.instance) // 메인 스레드 보장법
            .subscribe(onNext: {
                print("방출: \($0)")
            }, onError: { error in
                print("에러: \(error)")
            }, onCompleted: {
                print("완료")
            })
            .disposed(by: disposeBag)
    }
}

/*
 MARK: 이 스트림에서 에러가 나면 복구할 문제가 아니라 버그로 즉시 터져야 한다는 의도
 bind(onNext:) (대상: Observable)
 ─────────────────────────────────────
 역할
 - Observable의 값을 클로저에서 직접 처리한다
 - subscribe(onNext:)의 "안전한 축약 버전"

 특징
 - onNext만 처리 가능 (onError / onCompleted 없음)
 - 에러 발생 시 크래시
 - UI가 아니어도 사용 가능
 - 코드 의도가 subscribe보다 명확함

 스레드
 - ❌ 스레드 보장 없음
 - 필요하면 observe(on:)을 직접 지정해야 함

 에러
 - ❌ 에러 처리 불가
 - 에러 발생 시 즉시 크래시
 - 따라서 "에러가 발생하면 안 되는 스트림"에만 사용

 언제 사용하는가
 - 값 가공, 로그, 간단한 처리
 - 에러가 나면 안 되는 흐름
 - ViewModel 내부 로직

 한 줄 요약
 - ❝ 값은 내가 쓰되, 에러는 허용하지 않는다 ❞
 */
func bind() {
    runner(description: "bind(onNext:)") {
        let disposeBag = DisposeBag()
        let observable = Observable.of(1, 2, 3)
        
        observable
            .bind(onNext: { value in
                print("값 처리:", value * 2)
            })
            .disposed(by: disposeBag)
    }
}


/*
 bind(to:) (대상: Observable)
 MARK: 이 스트림의 값을 나는 해석하지 않고 에러가 없다는 전제 하에 다른 대상(UI, Relay, Subject)에 그대로 전달해 데이터 흐름만 선언하겠다
 MARK: bind(to:)는 값을 그대로 다른 대상에게 전달하므로 보통 Output에서 -> View로 UI를 붙일 때 사용하거나 거의 등장안한다
 ─────────────────────────────────────
 역할
 - Observable이 방출한 값을 다른 Observer에게 그대로 전달
 - 값을 "처리"하지 않고 "연결"만 담당

 특징
 - 값 소비자는 내가 아님
 - UI(Binder), Subject, Relay에만 사용 가능
 - 선언적인 데이터 흐름 표현
 - 실무에서 UI 바인딩의 기본 형태

 스레드
 - ❌ 스레드 보장 없음
 - UI 바인딩 시 반드시 MainScheduler에서 실행돼야 안전
   (또는 Driver 사용)

 에러
 - ❌ 에러 처리 불가
 - 에러 발생 시 크래시
 - UI 바인딩이므로 애초에 에러가 없어야 함

 언제 사용하는가
 - ViewModel → View(UI)
 - 상태 스트림 전달
 - 데이터 흐름을 명확히 표현하고 싶을 때

 한 줄 요약
 - ❝ 값은 저쪽에서 쓰고, 나는 흐름만 연결한다 ❞

 ex)
 viewModel.title
     .bind(to: label.rx.text)
     .disposed(by: bag)
 */



/*
 drive (대상: Driver)
 MARK: 이 스트림은 UI 전용이며, 메인 스레드에서 에러 없이 안전하게 전달되어야 한다는 의도
 MARK: drive는 UI에 꽂는 행위가 아니라, UI 규칙을 가진 스트림을 소비하는 전용 구독 방식이다.
 ─────────────────────────────────────
 역할
 - Driver가 방출하는 값을 UI(Binder)에 전달한다
 - UI 바인딩을 위한 최종 구독 방식

 특징
 - MainScheduler 보장 ⭕️ (자동)
 - 에러 방출 ❌ (Driver는 에러를 허용하지 않음)
 - replay(1) + share 상태
 - UI 업데이트에 최적화된 스트림

 스레드
 - ⭕️ 항상 MainScheduler에서 동작
 - observe(on:)을 직접 지정할 필요 없음

 에러
 - ❌ 에러 발생 불가
 - Driver 생성 시 반드시 에러를 제거해야 함
   (onErrorJustReturn / onErrorDriveWith 등)

 언제 사용하는가
 - View에서 Output을 UI에 바인딩할 때
 - UILabel, UIButton, UITableView 등 UI 업데이트
 - "UI는 실패하면 안 된다"는 전제가 있는 경우

 한 줄 요약
 - ❝ UI는 메인 스레드에서, 에러 없이 안전하게 ❞

 ex)
 viewModel.titleDriver
     .drive(label.rx.text)
     .disposed(by: bag)
 
 ex2)
 let disposeBag = DisposeBag()

 // 1️⃣ 일반 Observable
 let observable = Observable<String>.create { observer in
     observer.onNext("Hello")
     observer.onNext("RxSwift")
     observer.onError(NSError(domain: "TestError", code: -1))
     return Disposables.create()
 }

 // 2️⃣ Observable → Driver
 let driver = observable
     .asDriver(onErrorJustReturn: "❌ Error occurred")

 // 3️⃣ Driver subscribe (drive)
 driver
     .drive(onNext: { value in
         print("Driver received:", value)
     })
     .disposed(by: disposeBag)

 // CLI에서 run loop 유지
 RunLoop.main.run(until: Date(timeIntervalSinceNow: 1))
 */
























/*
 Bind
 - UI 컴포넌트와 Observable을 연결할 때 사용한다
 - Subscribe와 달리 onError 헨들러가 없어서 UI에서 발생가능한 크래시를 방지하기 위해 MainScheduler.instance에서 실행하게 해준다
 - 바인딩할 데이터 스트림에서 에러 발생 시 크래시 날 수 있음 주위
 - 그래서 catchErrorJustReturn(_:)을 활용한다
 
 let textField = UITextField()
 let label = UILabel()
 let disposeBag = DisposeBag()

 textField.rx.text.orEmpty
     .bind(to: label.rx.text)
     .disposed(by: disposeBag)
     
 let slider = UISlider()
 let label = UILabel()
 let disposeBag = DisposeBag()

 slider.rx.value
     .map { "\($0)" }
     .bind(to: label.rx.text)
     .disposed(by: disposeBag)
 */

/*
 driver
 - bind와 유사하지만 Driver타입만 허용
 - onErrorJustReturn(_:)을 사용해 에러 방지
 - MainScheduler.instance에서 자동 실행
 - UI 바인딩을 더욱 안전하게 수행 가능
 
 let textField = UITextField()
 let label = UILabel()
 let disposeBag = DisposeBag()

 let textDriver = textField.rx.text.orEmpty.asDriver(onErrorJustReturn: "")
 textDriver
     .drive(label.rx.text)
     .disposed(by: disposeBag)
 */

/*
 Subject / Relay는 “외부에서 들어온 이벤트를 받아서, ViewModel 내부 상태 흐름으로 편입시키기 위해” 쓴다.
 
 Observable
 - 나는 이미 정해진 규칙에 따라 값만 흘려보낸다
 - 외부에서 값을 넣을 수 없음
 - 오직 생성 시 정의된 로직만 실행
 - 외부 이벤트를 내가 직접 밀어 넣고 싶을 때”는 불가능
 
 외부 이벤트
 - 버튼탭
 - 화면진입
 - API결과
 - 내부 상태 변경
 
 Subject / Relay가 등장함
 - Observable + Observer
 - [ Input ] ──▶ Subject / Relay ──▶ 내부 상태 스트림 ──▶ Output
 
 Subject
 - PublishSubject
 - BehaviorSubject
 -> 에러 ⭕️
 -> completed ⭕️
 -> 비즈니스 로직용
 
 Relay (RxCocoa)
 - PublishRelay
 - BehaviorRelay
 -> 에러 ❌
 -> completed ❌
 -> UI / 상태 관리용
 
 final class ViewModel {

     // 🔹 내부 입력 저장소
     private let loadRelay = PublishRelay<Void>()
     private let stateRelay = BehaviorRelay<State>(value: .idle)

     struct Input {
         let load: Observable<Void>
     }

     struct Output {
         let state: Driver<State>
     }

     func transform(input: Input) -> Output {

         // Input → Relay (편입)
         input.load
             .bind(to: loadRelay)
             .disposed(by: bag)

         // Relay → 상태 생성
         loadRelay
             .map { State.loading }
             .bind(to: stateRelay)
             .disposed(by: bag)

         return Output(
             state: stateRelay.asDriver()
         )
     }
 }

 */
