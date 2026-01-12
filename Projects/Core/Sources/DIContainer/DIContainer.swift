//
//  DIContainer.swift
//  Core
//
//  Created by 김동현 on 1/12/26.
//

import Foundation

public final class DIContainer {
    public static let shared = DIContainer()
    private init() {}
    
    // 의존성을 등록할 딕셔너리를 선언
    private var dependencies: [String: Any] = [:]
    
    // 메서드로 의존성을 등록
    func register<T>(_ type: T.Type, dependency: T) {
        let key = String(describing: type)
        dependencies[key] = dependency
    }
    
    // 메서드로 등록된 의존성을 가져오기
    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        guard let dependency = dependencies[key] as? T else {
            preconditionFailure("⚠️ \(key)는 register되지 않았습니다. resolve호출 전에 register 해주세요.")
        }
        return dependency
    }
}

@propertyWrapper
public class Dependency<T> {
    public var wrappedValue: T
    public init() {
        self.wrappedValue = DIContainer.shared.resolve(T.self)
    }
}

/*
 https://medium.com/@songkiwon23/ios-swift-dicontainer-f8cc075b16e7
 https://velog.io/@kimscastle/iOS-DI-Container를-구현해보자feat.-Swinject
 // 의존성을 등록합니다.
DIContainer.shared.register(MyServiceProtocol.self, dependency: MyServiceImpl(myService: MyService()))

// 의존성을 해결하고 사용합니다.
if let myService = DIContainer.shared.resolve(MyServiceProtocol.self) {
    myService.performAction()
}
*/
