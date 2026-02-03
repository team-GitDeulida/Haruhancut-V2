//
//  1. Subject.swift
//  RxLabDemo
//
//  Created by 김동현 on 2/3/26.
//

import Foundation
import RxSwift


/*
 Subject
 MARK: Subject는 “밖에서 값을 밀어 넣을 수 있는 Observable”이다.
 MARK: 이 스트림은 외부에서 값을 직접 밀어 넣어야 하며, 그 값을 Observable처럼 여러 구독자에게 전달하려는 의도
 - Observable  = 값이 흘러나오기만 함 (읽기 전용)
 - Subject     = 값도 넣고(onNext), 구독도 가능 (읽기 + 쓰기)
 ─────────────────────────────────────
 역할
 - Observable이면서 동시에 Observer 역할을 수행
 - 외부에서 onNext로 값을 주입할 수 있는 스트림
 - “이벤트 입구” 역할

 특징
 - 값을 직접 주입(onNext) 가능
 - 여러 구독자에게 동일한 이벤트 전달
 - Observable 단독으로는 표현할 수 없는
   UI 이벤트, 상태 변경을 표현 가능

 스레드
 - ❌ 스레드 보장 없음
 - onNext를 호출한 스레드에서 그대로 방출
 - UI와 연결 시 observe(on:) 또는 Driver로 변환 필요

 에러
 - ⭕️ onError / onCompleted 가능
 - 한 번 에러 또는 완료되면 스트림 종료
 - 이후 onNext 호출 ❌

 언제 사용하는가
 - 버튼 탭, 화면 진입 등 외부 이벤트
 - View → ViewModel Input
 - “지금 이 순간 이 값을 흘려보내고 싶다”는 경우

 한 줄 요약
 - ❝ 외부 이벤트를 스트림 안으로 밀어 넣는 입구 ❞
 */


/*
 PublishSubject
 ─────────────────────────────────────
 특징
 - 구독 이후에 발생한 값만 전달
 - 이전 값은 저장하지 않음

 언제 사용하는가
 - 버튼 탭
 - 트리거성 이벤트

 한 줄 요약
 - ❝ 지금 발생한 이벤트만 흘려보낸다 ❞
 
 [출력]
 구독자1: A
 구독자1: B
 구독자1: C
 구독자2: C
 */
func subject_publish() {
    runner(description: "PublishSubject") {
        let disposeBag = DisposeBag()
        let subject = PublishSubject<String>()
        
        // 구독자 1
        subject
            .subscribe(onNext: { value in
                print("구독자1:", value)
            })
            .disposed(by: disposeBag)
        
        subject.onNext("A")
        subject.onNext("B")
        
        // 구독자 2 (늦게 구독)
        subject
            .subscribe(onNext: { value in
                print("구독자2:", value)
            })
            .disposed(by: disposeBag)
        
        subject.onNext("C")
    }
}

/*
 BehaviorSubject
 ─────────────────────────────────────
 특징
 - 항상 최근 값 1개를 저장
 - 새 구독자는 즉시 최신 값 수신

 언제 사용하는가
 - 현재 상태 표현
 - 초기값이 반드시 필요한 경우

 한 줄 요약
 - ❝ 항상 최신 상태를 들고 있는 스트림 ❞
 
 [출력]
 구독자1: 초기값
 구독자1: A
 구독자2: A
 구독자1: B
 구독자2: B
 */
func subject_behavior() {
    runner(description: "BehaviorSubject") {
        let disposeBag = DisposeBag()
        let subject = BehaviorSubject(value: "초기값")

        // 구독자 1
        subject
            .subscribe(onNext: { value in
                print("구독자1:", value)
            })
            .disposed(by: disposeBag)

        subject.onNext("A")

        // 구독자 2 (늦게 구독)
        subject
            .subscribe(onNext: { value in
                print("구독자2:", value)
            })
            .disposed(by: disposeBag)

        subject.onNext("B")
    }
}


/*
 ReplaySubject
 ─────────────────────────────────────
 특징
 - 최근 n개의 값을 저장
 - 새 구독자에게 저장된 값 재방출

 언제 사용하는가
 - 캐시
 - 로그, 히스토리성 데이터

 한 줄 요약
 - ❝ 과거 이벤트를 다시 들려준다 ❞
 
 [출력]
 구독자1: B
 구독자1: C
 구독자1: D
 구독자2: C
 구독자2: D
 */
func subject_replay() {
    runner(description: "ReplaySubject") {
        let disposeBag = DisposeBag()
        let subject = ReplaySubject<String>.create(bufferSize: 2)

        subject.onNext("A")
        subject.onNext("B")
        subject.onNext("C")

        // 구독자 1
        subject
            .subscribe(onNext: { value in
                print("구독자1:", value)
            })
            .disposed(by: disposeBag)

        subject.onNext("D")

        // 구독자 2
        subject
            .subscribe(onNext: { value in
                print("구독자2:", value)
            })
            .disposed(by: disposeBag)
    }
}


func subject_as_input() {
    runner(description: "Subject as Input") {
        let disposeBag = DisposeBag()
        let tapSubject = PublishSubject<Void>()

        // ViewModel 내부 로직 흉내
        tapSubject
            .bind(onNext: {
                print("버튼 탭 이벤트 처리")
            })
            .disposed(by: disposeBag)

        // View에서 이벤트 발생
        tapSubject.onNext(())
        tapSubject.onNext(())
    }
}
