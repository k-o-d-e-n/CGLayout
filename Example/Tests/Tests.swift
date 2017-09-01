import UIKit
import XCTest
@testable import CGLayout_Example
@testable import CGLayout

class Tests: XCTestCase {
    let bounds = UIScreen.main.bounds
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testLayout() {
        let leftOffset: CGFloat = 15
        let centerOffset: CGFloat = 10
        let horizontalScale: CGFloat = 1.5
        let verticalEdges = UIEdgeInsets.Vertical(top: 20, bottom: 100)

        let itemRect = CGRect(x: 400, y: 300, width: 200, height: 100)
        let sourceRect = CGRect(x: 0, y: 0, width: 1000, height: 500)

        let layout = Layout(alignment: .init(vertical: .center(centerOffset), horizontal: .left(leftOffset)),
                            filling: .init(vertical: .boxed(verticalEdges), horizontal: .scaled(horizontalScale)))

        let resultRect = layout.layout(rect: itemRect, in: sourceRect)
        XCTAssertTrue(resultRect.origin.x == leftOffset)
        XCTAssertTrue(resultRect.origin.y == ((sourceRect.height - resultRect.height) / 2) + centerOffset)
        XCTAssertTrue(resultRect.width == sourceRect.width * horizontalScale)
        XCTAssertTrue(resultRect.height == sourceRect.height - verticalEdges.full)
        print(resultRect)
    }

    func testPerformanceLayout() {
        let leftOffset: CGFloat = 15
        let centerOffset: CGFloat = 10
        let horizontalScale: CGFloat = 1.5
        let verticalEdges = UIEdgeInsets.Vertical(top: 20, bottom: 100)

        let sourceRect = CGRect(x: 0, y: 0, width: 1000, height: 500)

        let layout = Layout(alignment: .init(vertical: .center(centerOffset), horizontal: .left(leftOffset)),
                            filling: .init(vertical: .boxed(verticalEdges), horizontal: .scaled(horizontalScale)))

        let frames = (0..<1000).map { _ in CGRect.random(in: sourceRect) }

        self.measure {
            for itemRect in frames {
                _ = layout.layout(rect: itemRect, in: sourceRect)
            }
        }
    }
}

// MARK: Alignment

extension Tests {
    func testTopAlignment() {
        let view1 = UIView(frame: CGRect.random(in: bounds))
        let view2 = UIView(frame: CGRect.random(in: bounds))
        let alignment = Layout.Alignment.Vertical.top()

        alignment.layout(rect: &view1.frame, in: view2.frame)

        XCTAssertTrue(view1.frame.minY == view2.frame.minY)
    }

    func testTopAlignmentWithOffset() {
        let view1 = UIView(frame: CGRect.random(in: bounds))
        let view2 = UIView(frame: CGRect.random(in: bounds))
        let alignment = Layout.Alignment.Vertical.top(-10)

        alignment.layout(rect: &view1.frame, in: view2.frame)

        XCTAssertTrue(view1.frame.minY + 10 == view2.frame.minY)
    }

    func testBottomAlignment() {
        let view1 = UIView(frame: CGRect.random(in: bounds))
        let view2 = UIView(frame: CGRect.random(in: bounds))
        let alignment = Layout.Alignment.Vertical.bottom()

        alignment.layout(rect: &view1.frame, in: view2.frame)

        XCTAssertTrue(view1.frame.maxY == view2.frame.maxY)
    }

    func testBottomAlignmentWithOffset() {
        let view1 = UIView(frame: CGRect.random(in: bounds))
        let view2 = UIView(frame: CGRect.random(in: bounds))
        let alignment = Layout.Alignment.Vertical.bottom(10)

        alignment.layout(rect: &view1.frame, in: view2.frame)

        XCTAssertTrue(view1.frame.maxY + 10 == view2.frame.maxY)
    }

    func testLeftAlignment() {
        let view1 = UIView(frame: CGRect.random(in: bounds))
        let view2 = UIView(frame: CGRect.random(in: bounds))
        let alignment = Layout.Alignment.Horizontal.left()

        alignment.layout(rect: &view1.frame, in: view2.frame)

        XCTAssertTrue(view1.frame.minX == view2.frame.minX)
    }

    func testLeftAlignmentWithOffset() {
        let view1 = UIView(frame: CGRect.random(in: bounds))
        let view2 = UIView(frame: CGRect.random(in: bounds))
        let alignment = Layout.Alignment.Horizontal.left(-10)

        alignment.layout(rect: &view1.frame, in: view2.frame)

        XCTAssertTrue(view1.frame.minX + 10 == view2.frame.minX)
    }

    func testRightAlignment() {
        let view1 = UIView(frame: CGRect.random(in: bounds))
        let view2 = UIView(frame: CGRect.random(in: bounds))
        let alignment = Layout.Alignment.Horizontal.right()

        alignment.layout(rect: &view1.frame, in: view2.frame)

        XCTAssertTrue(view1.frame.maxX == view2.frame.maxX)
    }

    func testRightAlignmentWithOffset() {
        let view1 = UIView(frame: CGRect.random(in: bounds))
        let view2 = UIView(frame: CGRect.random(in: bounds))
        let alignment = Layout.Alignment.Horizontal.right(10)

        alignment.layout(rect: &view1.frame, in: view2.frame)

        XCTAssertTrue(view1.frame.maxX + 10 == view2.frame.maxX)
    }
}

// MARK: Filling

extension Tests {
    func testFillingConstantly() {
        let widthConstant: CGFloat = 45.7
        let heightConstant: CGFloat = 99.0
        var rect1 = CGRect.random(in: bounds)
        var rect2 = CGRect.random(in: bounds)
        let vertical = Layout.Filling.Vertical.constantly(heightConstant)
        let horizontal = Layout.Filling.Horizontal.constantly(widthConstant)

        vertical.layout(rect: &rect1, in: bounds) // second parameter has no effect in this case
        horizontal.layout(rect: &rect2, in: bounds) // second parameter has no effect in this case

        XCTAssertTrue(rect1.height == heightConstant)
        XCTAssertTrue(rect2.width == widthConstant)
    }

    func testFillingScaled() {
        let widthScale: CGFloat = 0.7
        let heightScale: CGFloat = 1.4
        let rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)
        let vertical = Layout.Filling.Vertical.scaled(heightScale)
        let horizontal = Layout.Filling.Horizontal.scaled(widthScale)

        var resultRect1 = rect1
        var resultRect2 = rect2
        vertical.layout(rect: &resultRect1, in: rect2)
        horizontal.layout(rect: &resultRect2, in: rect1)

        XCTAssertTrue(resultRect1.height == rect2.height * heightScale)
        XCTAssertTrue(resultRect2.width == rect1.width * widthScale)
    }

    func testFillingBoxed() {
        let widthBox = UIEdgeInsets.Horizontal(left: 20, right: -15)
        let heightBox = UIEdgeInsets.Vertical(top: 20, bottom: -30)
        let rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)
        let vertical = Layout.Filling.Vertical.boxed(heightBox)
        let horizontal = Layout.Filling.Horizontal.boxed(widthBox)

        var resultRect1 = rect1
        var resultRect2 = rect2
        vertical.layout(rect: &resultRect1, in: rect2)
        horizontal.layout(rect: &resultRect2, in: rect1)

        XCTAssertTrue(resultRect1.height == max(0, rect2.height - heightBox.full))
        XCTAssertTrue(resultRect2.width == max(0, rect1.width - widthBox.full))
    }
}

// MARK: LayoutAnchor

extension Tests {
    func testAnchorBottomAlign() {
        let outer = LayoutAnchor.Bottom.alignBy(inner: false)
        var rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)

        let inner = LayoutAnchor.Bottom.alignBy(inner: true)
        var rect3 = CGRect.random(in: bounds)
        let rect4 = CGRect.random(in: bounds)

        outer.constrain(sourceRect: &rect1, by: rect2)
        inner.constrain(sourceRect: &rect3, by: rect4)

        XCTAssertTrue(rect1.minY == rect2.maxY)
        XCTAssertTrue(rect3.maxY == rect4.maxY)
    }
    func testAnchorBottomLimit() {
        let outer = LayoutAnchor.Bottom.limitOn(inner: false)
        let rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)
        let isRect1AboveBottomRect2 = rect1.maxY <= rect2.maxY
        let isRect1BelowBottomRect2 = rect1.minY >= rect2.maxY

        let inner = LayoutAnchor.Bottom.limitOn(inner: true)
        let rect3 = CGRect.random(in: bounds)
        let rect4 = CGRect.random(in: bounds)
        let isRect3AboveBottomRect4 = rect3.maxY <= rect4.maxY
        let isRect3BelowBottomRect4 = rect3.minY >= rect4.maxY

        var resultRect1 = rect1
        var resultRect3 = rect3
        outer.constrain(sourceRect: &resultRect1, by: rect2)
        inner.constrain(sourceRect: &resultRect3, by: rect4)

        if isRect1AboveBottomRect2 {
            XCTAssertTrue(resultRect1.minY == rect2.maxY)
        } else if isRect1BelowBottomRect2 {
            XCTAssertTrue(resultRect1 == rect1)
        } else {
            XCTAssertTrue(resultRect1.minY == rect2.maxY)
            XCTAssertTrue(resultRect1.height == rect1.maxY - rect2.maxY)
        }
        if isRect3AboveBottomRect4 {
            XCTAssertTrue(resultRect3 == rect3)
        } else if isRect3BelowBottomRect4 {
            XCTAssertTrue(resultRect3.maxY == rect4.maxY)
        } else {
            XCTAssertTrue(resultRect3.maxY == rect4.maxY)
            XCTAssertTrue(resultRect3.height == rect3.divided(atDistance: rect3.maxY - rect4.maxY, from: .maxYEdge).remainder.height)
        }
    }
    func testAnchorBottomPull() {
        let outer = LayoutAnchor.Bottom.pullFrom(inner: false)
        let rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)
        let isBottomRect1BelowBottomRect2 = rect1.maxY > rect2.maxY

        let inner = LayoutAnchor.Bottom.pullFrom(inner: true)
        let rect3 = CGRect.random(in: bounds)
        let rect4 = CGRect.random(in: bounds)
        let isTopRect3AboveBottomRect4 = rect3.minY < rect4.maxY

        var resultRect1 = rect1
        var resultRect3 = rect3
        outer.constrain(sourceRect: &resultRect1, by: rect2)
        inner.constrain(sourceRect: &resultRect3, by: rect4)

        XCTAssertTrue(resultRect1.minY == rect2.maxY, "\(resultRect1, rect1, rect2)")
        if isBottomRect1BelowBottomRect2 {
            XCTAssertTrue(resultRect1.height == rect1.maxY - rect2.maxY)
        }
        XCTAssertTrue(resultRect3.maxY == rect4.maxY)
        XCTAssertTrue(resultRect3.height == max(0, rect4.maxY - rect3.minY))
        if isTopRect3AboveBottomRect4 {
            XCTAssertTrue(resultRect3.minY == rect3.minY)
        }
    }
}

extension CGRect {
    static func random(in source: CGRect) -> CGRect {
        let o = CGPoint(x: CGFloat(arc4random_uniform(UInt32(source.width))), y: CGFloat(arc4random_uniform(UInt32(source.height))))
        let s = CGSize(width: CGFloat(arc4random_uniform(UInt32(source.width - o.x))), height: CGFloat(arc4random_uniform(UInt32(source.height - o.y))))

        return CGRect(origin: o, size: s)
    }
}
