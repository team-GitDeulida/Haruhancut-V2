//
//  Operators.swift
//  RxLabDemo
//
//  Created by 김동현 on 2/3/26.
//

import RxSwift
import Foundation

/*
 MARK: Operators (연산자)
 ─────────────────────────────────────
 연산자는 Observable이 흘려보내는 값을
 "변환 / 조합 / 제어"하는 함수들이다.

 핵심 개념
 - Observable을 다른 Observable로 바꾼다
 - 원본은 건드리지 않는다 (불변)
 - 연산자 체인은 "데이터 파이프라인"이다
 */

/*
 map
 ─────────────────────────────────────
 역할
 - 방출된 값을 다른 값으로 변환

 특징
 - 1 : 1 변환
 - 가장 기본적인 연산자

 언제 사용하는가
 - 모델 → 뷰모델
 - 타입 변환
 - 값 가공

 한 줄 요약
 - ❝ 값을 다른 값으로 바꾼다 ❞
 */
func map() {
    runner(description: "map") {
        let disposeBag = DisposeBag()
        Observable.of(1, 2, 3)
            .map { $0 * 2 }
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)
        // 2, 4, 6
    }
}

/*
 filter
 ─────────────────────────────────────
 역할
 - 조건에 맞는 값만 통과

 특징
 - true → 통과
 - false → 버림

 언제 사용하는가
 - 유효성 검사
 - 조건부 처리

 한 줄 요약
 - ❝ 필요한 값만 흘려보낸다 ❞
 */
func filter() {
    runner(description: "filter") {
        let disposeBag = DisposeBag()
        Observable.of(1, 2, 3, 4)
            .filter { $0.isMultiple(of: 2) }
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)
        // 2, 4
    }
}

/*
 flatMap
 ─────────────────────────────────────
 역할
 - 값 → Observable로 변환 후 병합

 특징
 - 비동기 작업 연결
 - 여러 스트림이 동시에 살아 있음

 언제 사용하는가
 - API 체이닝
 - Observable 안에서 Observable 반환

 한 줄 요약
 - ❝ Observable을 펼쳐서 하나로 만든다 ❞
 */
func flatMap() {
    runner(description: "flatMap") {
        let disposeBag = DisposeBag()
        Observable.of(1, 2)
            .flatMap { value in
                Observable.of(value * 10)
            }
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)
        // 10, 20
    }
}

/*
 flatMapLatest
 ─────────────────────────────────────
 역할
 - 가장 최신 Observable만 유지

 특징
 - 이전 작업은 자동 취소
 - UI 입력 처리의 핵심

 언제 사용하는가
 - 검색
 - 버튼 연타 방지

 한 줄 요약
 - ❝ 최신 것만 살아남는다 ❞
 
 searchText
     .flatMapLatest { query in
         api.search(query)
     }
 */
func flatMapLatest() {
    runner(description: "flatMapLatest") {
        let disposeBag = DisposeBag()
        let subject = PublishSubject<Int>()

        subject
            .flatMapLatest { value in
                Observable<Int>.just(value)
            }
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)

        subject.onNext(1)
        subject.onNext(2)
        subject.onNext(3)
    }
}

/*
 merge
 ─────────────────────────────────────
 역할
 - 여러 Observable을 하나로 합침

 특징
 - 순서 보장 ❌
 - 먼저 오는 대로 방출

 언제 사용하는가
 - 여러 이벤트 소스 통합

 한 줄 요약
 - ❝ 여러 파이프를 하나로 ❞
 */
func merge() {
    runner(description: "merge") {
        let a = Observable<Int>.just(1)
        let b = Observable<Int>.just(2)
        let disposeBag = DisposeBag()
        Observable.merge(a, b)
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)
        
        // 1, 2
    }
}

/*
 combineLatest
 ─────────────────────────────────────
 역할
 - 최신 값들을 조합

 특징
 - 모든 Observable이 한 번 이상 값 방출해야 동작

 언제 사용하는가
 - 입력 폼 검증
 - 상태 조합

 한 줄 요약
 - ❝ 최신 상태들을 묶는다 ❞
 
 Observable.combineLatest(id, password)
     .map { !$0.isEmpty && !$1.isEmpty }
 */
func combineLatest() {
    runner(description: "combineLatest") {
        let disposeBag = DisposeBag()
        let id = PublishSubject<String>()
        let pw = PublishSubject<String>()

        Observable.combineLatest(id, pw)
            .subscribe(onNext: { print("id:", $0, "pw:", $1) })
            .disposed(by: disposeBag)

        id.onNext("user")
        pw.onNext("1234")
        pw.onNext("5678")
    }
}


/*
 withLatestFrom
 ─────────────────────────────────────
 역할
 - 트리거 시점에 다른 스트림의 최신 값 사용

 특징
 - 기준 스트림이 명확

 언제 사용하는가
 - 버튼 탭 + 현재 입력값

 한 줄 요약
 - ❝ 누를 때 최신 값을 가져온다 ❞
 
 submitTap
     .withLatestFrom(formData)
 */
func withLatestFrom() {
    runner(description: "withLatestFrom") {
        let disposeBag = DisposeBag()
        let tap = PublishSubject<Void>()
        let text = PublishSubject<String>()

        tap
            .withLatestFrom(text)
            .subscribe(onNext: { print("전송:", $0) })
            .disposed(by: disposeBag)

        text.onNext("Hello")
        tap.onNext(())
        text.onNext("RxSwift")
        tap.onNext(())
    }
}

/*
 debounce
 ─────────────────────────────────────
 역할
 - 일정 시간 동안 입력이 멈췄을 때만 방출

 언제 사용하는가
 - 검색창

 한 줄 요약
 - ❝ 잠깐 기다렸다가 한 번 ❞
 
 searchText
     .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
 */
func debounce() {
    runner(description: "debounce") {
        let disposeBag = DisposeBag()
        let subject = PublishSubject<String>()

        subject
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)

        subject.onNext("H")
        subject.onNext("He")
        subject.onNext("Hel")
        subject.onNext("Hell")
        subject.onNext("Hello")

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1))
    }
}

/*
 throttle
 ─────────────────────────────────────
 역할
 - 일정 시간 동안 한 번만 허용

 언제 사용하는가
 - 버튼 연타 방지

 한 줄 요약
 - ❝ 너무 자주 오면 막는다 ❞
 */
func throttle() {
    runner(description: "throttle") {
        let disposeBag = DisposeBag()
        let subject = PublishSubject<String>()

        subject
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)

        subject.onNext("A")
        subject.onNext("B")
        subject.onNext("C")

        RunLoop.main.run(until: Date(timeIntervalSinceNow: 1))
    }
}


/*
 distinctUntilChanged
 ─────────────────────────────────────
 역할
 - 이전 값과 같으면 방출하지 않음

 언제 사용하는가
 - 중복 UI 업데이트 방지

 한 줄 요약
 - ❝ 같은 값이면 무시 ❞
 */
func distinctUntilChanged() {
    runner(description: "distinctUntilChanged") {
        let disposeBag = DisposeBag()

        Observable.of(1, 1, 2, 2, 3, 3)
            .distinctUntilChanged()
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)
    }
}

/*
 take / skip
 ─────────────────────────────────────
 역할
 - take(n): 앞에서 n개만
 - skip(n): 앞에서 n개 버림

 한 줄 요약
 - ❝ 일부만 선택 ❞
 */
func take_skip() {
    runner(description: "take / skip") {
        let disposeBag = DisposeBag()

        Observable.of(1, 2, 3, 4, 5)
            .skip(2)
            .take(2)
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)
    }
}

