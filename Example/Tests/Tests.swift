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

// TODO: Separate inner and outer, also positions frames to yourself tests
extension Tests {
    func testAnchorBottomAlign() {
        let outer = LayoutAnchor.Bottom.align(by: .outer)
        var rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)

        let inner = LayoutAnchor.Bottom.align(by: .inner)
        var rect3 = CGRect.random(in: bounds)
        let rect4 = CGRect.random(in: bounds)

        outer.constrain(sourceRect: &rect1, by: rect2)
        inner.constrain(sourceRect: &rect3, by: rect4)

        XCTAssertTrue(rect1.minY == rect2.maxY)
        XCTAssertTrue(rect3.maxY == rect4.maxY)
    }
    func testAnchorBottomLimit() {
        let outer = LayoutAnchor.Bottom.limit(on: .outer)
        let rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)
        let isRect1AboveBottomRect2 = rect1.maxY <= rect2.maxY
        let isRect1BelowBottomRect2 = rect1.minY >= rect2.maxY

        let inner = LayoutAnchor.Bottom.limit(on: .inner)
        let rect3 = CGRect.random(in: bounds)
        let rect4 = CGRect.random(in: bounds)
        let isRect3AboveBottomRect4 = rect3.maxY <= rect4.maxY
        let isRect3BelowBottomRect4 = rect3.minY >= rect4.maxY

        var resultRect1 = rect1
        var resultRect3 = rect3
        outer.constrain(sourceRect: &resultRect1, by: rect2)
        inner.constrain(sourceRect: &resultRect3, by: rect4)

        if isRect1AboveBottomRect2 {
            XCTAssertTrue(resultRect1.maxY == rect2.maxY)
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
            XCTAssertTrue(resultRect3.minY == rect4.maxY)
            XCTAssertTrue(resultRect3.maxY == rect4.maxY)
        } else {
            XCTAssertTrue(resultRect3.maxY == rect4.maxY)
            XCTAssertTrue(resultRect3.height == rect3.divided(atDistance: rect3.maxY - rect4.maxY, from: .maxYEdge).remainder.height)
        }
    }
    func testAnchorBottomPull() {
        let outer = LayoutAnchor.Bottom.pull(from: .outer)
        let rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)
        let isBottomRect1BelowBottomRect2 = rect1.maxY > rect2.maxY

        let inner = LayoutAnchor.Bottom.pull(from: .inner)
        let rect3 = CGRect.random(in: bounds)
        let rect4 = CGRect.random(in: bounds)
        let isTopRect3AboveBottomRect4 = rect3.minY < rect4.maxY

        var resultRect1 = rect1
        var resultRect3 = rect3
        outer.constrain(sourceRect: &resultRect1, by: rect2)
        inner.constrain(sourceRect: &resultRect3, by: rect4)

        XCTAssertTrue(resultRect1.minY == rect2.maxY)
        if isBottomRect1BelowBottomRect2 {
            XCTAssertTrue(resultRect1.height == rect1.maxY - rect2.maxY)
        }
        XCTAssertTrue(resultRect3.maxY == rect4.maxY)
        XCTAssertTrue(resultRect3.height == max(0, rect4.maxY - rect3.minY))
        if isTopRect3AboveBottomRect4 {
            XCTAssertTrue(resultRect3.minY == rect3.minY)
        }
    }
    
    func testAnchorRightAlign() {
        let outer = LayoutAnchor.Right.align(by: .outer)
        var rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)

        let inner = LayoutAnchor.Right.align(by: .inner)
        var rect3 = CGRect.random(in: bounds)
        let rect4 = CGRect.random(in: bounds)

        outer.constrain(sourceRect: &rect1, by: rect2)
        inner.constrain(sourceRect: &rect3, by: rect4)

        XCTAssertTrue(rect1.minX == rect2.maxX)
        XCTAssertTrue(rect3.maxX == rect4.maxX)
    }
    func testAnchorRightLimit() {
        let outer = LayoutAnchor.Right.limit(on: .outer)
        let rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)
        let isRect1BeforeRightRect2 = rect1.maxX <= rect2.maxX
        let isRect1AfterRightRect2 = rect1.minX >= rect2.maxX

        let inner = LayoutAnchor.Right.limit(on: .inner)
        let rect3 = CGRect.random(in: bounds)
        let rect4 = CGRect.random(in: bounds)
        let isRect3BeforeRightRect4 = rect3.maxX <= rect4.maxX
        let isRect3AfterRightRect4 = rect3.minX >= rect4.maxX

        var resultRect1 = rect1
        var resultRect3 = rect3
        outer.constrain(sourceRect: &resultRect1, by: rect2)
        inner.constrain(sourceRect: &resultRect3, by: rect4)

        if isRect1BeforeRightRect2 {
            XCTAssertTrue(resultRect1.maxX == rect2.maxX)
            XCTAssertTrue(resultRect1.minX == rect2.maxX)
        } else if isRect1AfterRightRect2 {
            XCTAssertTrue(resultRect1 == rect1)
        } else {
            XCTAssertTrue(resultRect1.minX == rect2.maxX)
            XCTAssertTrue(resultRect1.width == rect1.maxX - rect2.maxX)
        }
        if isRect3BeforeRightRect4 {
            XCTAssertTrue(resultRect3 == rect3)
        } else if isRect3AfterRightRect4 {
            XCTAssertTrue(resultRect3.minX == rect4.maxX)
            XCTAssertTrue(resultRect3.maxX == rect4.maxX)
        } else {
            XCTAssertTrue(resultRect3.maxX == rect4.maxX)
            XCTAssertTrue(resultRect3.width == rect3.divided(atDistance: rect3.maxX - rect4.maxX, from: .maxXEdge).remainder.width)
        }
    }
    func testAnchorRightPull() {
        let outer = LayoutAnchor.Right.pull(from: .outer)
        let rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)
        let isRightRect1AfterRightRect2 = rect1.maxX > rect2.maxX

        let inner = LayoutAnchor.Right.pull(from: .inner)
        let rect3 = CGRect.random(in: bounds)
        let rect4 = CGRect.random(in: bounds)
        let isLeftRect3BeforeRightRect4 = rect3.minX < rect4.maxX

        var resultRect1 = rect1
        var resultRect3 = rect3
        outer.constrain(sourceRect: &resultRect1, by: rect2)
        inner.constrain(sourceRect: &resultRect3, by: rect4)

        XCTAssertTrue(resultRect1.minX == rect2.maxX, "\(resultRect1, rect1, rect2)")
        if isRightRect1AfterRightRect2 {
            XCTAssertTrue(resultRect1.width == rect1.maxX - rect2.maxX)
        }
        XCTAssertTrue(resultRect3.maxX == rect4.maxX)
        XCTAssertTrue(resultRect3.width == max(0, rect4.maxX - rect3.minX))
        if isLeftRect3BeforeRightRect4 {
            XCTAssertTrue(resultRect3.minX == rect3.minX)
        }
    }

    func testAnchorLeftAlign() {
        let outer = LayoutAnchor.Left.align(by: .outer)
        var rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)

        let inner = LayoutAnchor.Left.align(by: .inner)
        var rect3 = CGRect.random(in: bounds)
        let rect4 = CGRect.random(in: bounds)

        outer.constrain(sourceRect: &rect1, by: rect2)
        inner.constrain(sourceRect: &rect3, by: rect4)

        XCTAssertTrue(rect1.maxX == rect2.minX)
        XCTAssertTrue(rect3.minX == rect4.minX)
    }
    func testAnchorLeftLimit() {
        let outer = LayoutAnchor.Left.limit(on: .outer)
        let rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)
        let isRect1BeforeLeftRect2 = rect1.maxX <= rect2.minX
        let isRect1AfterLeftRect2 = rect1.minX >= rect2.minX

        let inner = LayoutAnchor.Left.limit(on: .inner)
        let rect3 = CGRect.random(in: bounds)
        let rect4 = CGRect.random(in: bounds)
        let isRect3BeforeLeftRect4 = rect3.maxX <= rect4.minX
        let isRect3AfterLeftRect4 = rect3.minX >= rect4.minX

        var resultRect1 = rect1
        var resultRect3 = rect3
        outer.constrain(sourceRect: &resultRect1, by: rect2)
        inner.constrain(sourceRect: &resultRect3, by: rect4)

        if isRect1AfterLeftRect2 {
            XCTAssertTrue(resultRect1.maxX == rect2.minX)
            XCTAssertTrue(resultRect1.minX == rect2.minX)
        } else if isRect1BeforeLeftRect2 {
            XCTAssertTrue(resultRect1 == rect1)
        } else {
            XCTAssertTrue(resultRect1.maxX == rect2.minX)
            XCTAssertTrue(resultRect1.width == rect2.minX - rect1.minX)
        }
        if isRect3AfterLeftRect4 {
            XCTAssertTrue(resultRect3 == rect3)
        } else if isRect3BeforeLeftRect4 {
            XCTAssertTrue(resultRect3.minX == rect4.minX)
            XCTAssertTrue(resultRect3.maxX == rect4.minX)
        } else {
            XCTAssertTrue(resultRect3.minX == rect4.minX)
            XCTAssertTrue(resultRect3.width == rect3.divided(atDistance: rect4.minX - rect3.minX, from: .minXEdge).remainder.width)
        }
    }
    func testAnchorLeftPull() {
        let outer = LayoutAnchor.Left.pull(from: .outer)
        let rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)
        let isLeftRect1BeforeLeftRect2 = rect1.minX < rect2.minX

        let inner = LayoutAnchor.Left.pull(from: .inner)
        let rect3 = CGRect.random(in: bounds)
        let rect4 = CGRect.random(in: bounds)
        let isRightRect3BeforeLeftRect4 = rect3.maxX < rect4.minX

        var resultRect1 = rect1
        var resultRect3 = rect3
        outer.constrain(sourceRect: &resultRect1, by: rect2)
        inner.constrain(sourceRect: &resultRect3, by: rect4)

        XCTAssertTrue(resultRect1.maxX == rect2.minX)
        if isLeftRect1BeforeLeftRect2 {
            XCTAssertTrue(resultRect1.width == rect2.minX - rect1.minX)
        }
        XCTAssertTrue(resultRect3.minX == rect4.minX)
        XCTAssertTrue(resultRect3.width == max(0, rect3.maxX - rect4.minX))
        if isRightRect3BeforeLeftRect4 {
            XCTAssertTrue(resultRect3.maxX == rect3.minX)
        }
    }

    func testAnchorTopAlign() {
        let outer = LayoutAnchor.Top.align(by: .outer)
        var rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)

        let inner = LayoutAnchor.Top.align(by: .inner)
        var rect3 = CGRect.random(in: bounds)
        let rect4 = CGRect.random(in: bounds)

        outer.constrain(sourceRect: &rect1, by: rect2)
        inner.constrain(sourceRect: &rect3, by: rect4)

        XCTAssertTrue(rect1.bottom == rect2.top)
        XCTAssertTrue(rect3.top == rect4.top)
    }
    func testAnchorTopLimit() {
        let outer = LayoutAnchor.Top.limit(on: .outer)
        let rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)
        let isRect1AboveTopRect2 = rect1.bottom <= rect2.top
        let isRect1BelowTopRect2 = rect1.top >= rect2.top

        let inner = LayoutAnchor.Top.limit(on: .inner)
        let rect3 = CGRect.random(in: bounds)
        let rect4 = CGRect.random(in: bounds)
        let isRect3AboveTopRect4 = rect3.bottom <= rect4.top
        let isRect3BelowTopRect4 = rect3.top >= rect4.top

        var resultRect1 = rect1
        var resultRect3 = rect3
        outer.constrain(sourceRect: &resultRect1, by: rect2)
        inner.constrain(sourceRect: &resultRect3, by: rect4)

        if isRect1BelowTopRect2 {
            XCTAssertTrue(resultRect1.maxY == rect2.minY)
            XCTAssertTrue(resultRect1.minY == rect2.minY)
        } else if isRect1AboveTopRect2 {
            XCTAssertTrue(resultRect1 == rect1)
        } else {
            XCTAssertTrue(resultRect1.maxY == rect2.minY)
            XCTAssertTrue(resultRect1.height == rect2.minY - rect1.minY)
        }
        if isRect3BelowTopRect4 {
            XCTAssertTrue(resultRect3 == rect3)
        } else if isRect3AboveTopRect4 {
            XCTAssertTrue(resultRect3.minY == rect4.minY)
            XCTAssertTrue(resultRect3.maxY == rect4.minY)
        } else {
            XCTAssertTrue(resultRect3.minY == rect4.minY)
            XCTAssertTrue(resultRect3.height == rect3.divided(atDistance: rect4.minY - rect3.minY, from: .minYEdge).remainder.height)
        }
    }
    func testAnchorTopPull() {
        let outer = LayoutAnchor.Top.pull(from: .outer)
        let rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)
        let isTopRect1AboveTopRect2 = rect1.top < rect2.top

        let inner = LayoutAnchor.Top.pull(from: .inner)
        let rect3 = CGRect.random(in: bounds)
        let rect4 = CGRect.random(in: bounds)
        let isBottomRect3AboveTopRect4 = rect3.bottom < rect4.top

        var resultRect1 = rect1
        var resultRect3 = rect3
        outer.constrain(sourceRect: &resultRect1, by: rect2)
        inner.constrain(sourceRect: &resultRect3, by: rect4)

        XCTAssertTrue(resultRect1.maxY == rect2.minY)
        if isTopRect1AboveTopRect2 {
            XCTAssertTrue(resultRect1.height == rect2.minY - rect1.minY)
        }
        XCTAssertTrue(resultRect3.minY == rect4.minY)
        XCTAssertTrue(resultRect3.height == max(0, rect3.maxY - rect4.minY))
        if isBottomRect3AboveTopRect4 {
            XCTAssertTrue(resultRect3.maxY == rect3.minY)
        }
    }
}

extension Tests {
    func testPerformanceLayoutSecondViewController() {
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SecondViewController")
        controller.loadViewIfNeeded()

        self.measure {
            controller.view.setNeedsLayout()
            controller.view.layoutIfNeeded()
        }
    }
    func testPerformanceAutoLayoutSecondViewController() {
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SecondViewControllerAutoLayout")
        controller.loadViewIfNeeded()

        self.measure {
            controller.view.setNeedsLayout()
            controller.view.layoutIfNeeded()
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
