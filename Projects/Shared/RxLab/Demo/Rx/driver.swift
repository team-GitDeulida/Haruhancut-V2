//
//  driver.swift
//  RxLabDemo
//
//  Created by 김동현 on 1/16/26.
//

import Foundation
import RxSwift
import RxRelay

/*
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
