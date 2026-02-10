//
//  Empty.swift
//  Core
//
//  Created by 김동현 on 
//
import XCTest
@testable import Core

/*
XCTAssertEqual(user.uid, id)
XCTAssertTrue(true)
func test_import_core() {
    _ = String(describing: type(of: self))
    XCTAssertTrue(true)
}
 */
final class SmokeTest: XCTestCase {
    func test_import_core() {
        _ = String(describing: type(of: self))
        XCTAssertTrue(true)
    }
}


