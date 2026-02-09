//
//  Empty.swift
//  Core
//
//  Created by 김동현 on 
//
import XCTest
@testable import Core
//import Domain

// final class UserTests: XCTestCase {

//     func test_init_shouldSetPropertiesCorrectly() {
//         // given
//         let id = "stub-uid"
//         let nickname = "stub-nickname-apple"

//         // when
//         // let user = User.sampleUser1

//         // then
//         // XCTAssertEqual(user.uid, id)
//         // XCTAssertEqual(user.nickname, nickname)
//     }
// }
final class SmokeTest: XCTestCase {
    func test_import_core() {
        _ = String(describing: type(of: self))
        XCTAssertTrue(true)
        
    }
}


