//
//  CGLayout_macOSTests.swift
//  CGLayout-macOSTests
//
//  Created by Denis Koryttsev on 03/10/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import XCTest
@testable import CGLayout

class CGLayout_macOSTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testEdgeInsetsApplyRect() {
        var rect = CGRect(x: 20, y: 10, width: 100, height: 200)
        let insets = EdgeInsets(top: 20, left: -5, bottom: 10, right: 0)

        rect.apply(edgeInsets: insets)

        XCTAssertTrue(rect == CGRect(x: 15, y: 30, width: 105, height: 170))
    }
    
}
