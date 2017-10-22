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
    func testCoordinateSpaceCGRect() {
        let window = NSApplication.shared().mainWindow!
        let bounds = window.frame
        let superview = NSScrollView(frame: bounds.insetBy(dx: 100, dy: 100))
        window.contentView = superview
        superview.documentView = NSView(frame: bounds)
        superview.documentView?.scroll(NSPoint(x: 150, y: superview.documentView!.frame.origin.y))
        let view = LayoutPlaceholder<NSView, NSView>(frame: CGRect(x: 20, y: 10, width: 40, height: 60))
        superview.add(layoutGuide: view)

        let converted = view.convert(rect: CGRect(x: 10, y: -5, width: 20, height: 10), to: superview)
        let converted2 = view.convert(rect: CGRect(x: 150, y: 0, width: 30, height: 20), from: superview)

        XCTAssertTrue(converted.origin.x == 30)
        XCTAssertTrue(converted.origin.y == 5)

        XCTAssertTrue(converted2.origin.x == 130)
        XCTAssertTrue(converted2.origin.y == -10)
    }
}
