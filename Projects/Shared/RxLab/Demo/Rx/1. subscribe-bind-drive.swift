//
//  subscribe-bind-drive.swift
//  RxLabDemo
//
//  Created by 김동현 on 1/16/26.
//

import Foundation
import RxSwift

/*
 https://green1229.tistory.com/549
 Subscribe
 - 모든 Observable에서 사용 가능
 - onNext, onError, onCompleted 핸들링 가능
 - 에러 처리 직접 해야함
 - 메인 스레드를 보장하지 않아 UI 바인딩에 적합하지 않음
 
 언제 사용하는가
 - 일반적인 데이터 스트림 처리할 때
 - API 호출 후 데이터 가공하는 경우
 - Rx기반 이벤트 처리시
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
