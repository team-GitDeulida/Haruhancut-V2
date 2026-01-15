////
////  SignInPresentable.swift
////  Auth
////
////  Created by 김동현 on 
////
//
//import UIKit
//
///// SignIn Feature에서 발생하는
///// **의미 있는 이벤트를 외부로 전달하기 위한 계약**
/////
///// - 화면 전환 로직을 View / ViewModel 밖으로 분리하기 위한 트리거
///// - "회원가입 버튼이 눌림", "로그인 성공"과 같은
/////   **사실(Event)만 외부에 알린다**
//public protocol AuthRoutingTrigger {
//    var onAuthCompleted: (() -> Void)? { get set }
//}
//
///// Feature 공통 ViewModel 인터페이스
/////
///// - 모든 Feature ViewModel이 따르는 최소 단위 프로토콜
///// - 기능은 없으며, "이 타입은 ViewModel이다"라는
/////   **의미적 태그(Marker Protocol)** 역할
//public protocol ViewModelType {}
//
///// SignIn Feature가 요구하는 ViewModel 계약
/////
///// - ViewModelType 을 만족해야 하며
///// - SignInRoutingTrigger 를 통해
/////   외부로 이벤트를 전달할 수 있어야 한다
//public typealias AuthViewModelType = ViewModelType & AuthRoutingTrigger
//
//// MARK: - Product
///// SignIn Feature의 **조립된 결과물(Product)**
/////
///// - `vc` : 화면에 표시할 ViewController
///// - `vm` : 외부에서 이벤트를 바인딩할 ViewModel
/////
///// Coordinator 는 이 Product 를 통해
///// 화면 표시와 흐름 제어를 수행한다
//public typealias SignInPresentable = (vc: UIViewController,
//                                      vm: AuthViewModelType)
//
//// MARK: - Concrete Product
///// SignInPresentable를 튜플로 만들면
///// return (vc: viewController, vm: viewModel)
///// 이 생성된 튜플 인스턴스 자체가 Concrete Product가 된다
//
//
///*
// public protocol SignInPresentable {
//     var viewController: UIViewController { get }
//     var viewModel: SignInViewModelType { get }
// }
//
//struct SignInFeature: SignInPresentable {
//    var viewController: UIViewController
//    var viewModel: SignInViewModelType
//}
//*/
