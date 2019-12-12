import XCTest
@testable import CGLayout

#if os(iOS)
    typealias View = UIView
    typealias Window = UIWindow
    typealias Label = UILabel
#elseif os(macOS)
    typealias View = NSView
    typealias Window = NSWindow
#endif

#if !os(Linux)
    typealias Layer = CALayer
#endif

extension CGRect {
    static func random(in source: CGRect) -> CGRect {
        let randomValue: (CGFloat) -> CGFloat = { pattern -> CGFloat in
            #if os(Linux)
            return CGFloat(SwiftGlibc.random() % Int(pattern))
            #else
            return CGFloat(arc4random_uniform(UInt32(pattern)))
            #endif
        }
        let o = CGPoint(x: randomValue(source.width), y: randomValue(source.height))
        let s = CGSize(width: randomValue(source.width - o.x), height: randomValue(source.height - o.y))

        return CGRect(origin: o, size: s)
    }
}

class Tests: XCTestCase {
    let bounds = CGRect(x: 0, y: 0, width: 1024, height: 800)
    
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
        let edges = EdgeInsets(top: 20, left: 0, bottom: 100, right: 0)

        let itemRect = CGRect(x: 400, y: 300, width: 200, height: 100)
        let sourceRect = CGRect(x: 0, y: 0, width: 1000, height: 500)

        let layout = Layout(alignment: .init(horizontal: .left(leftOffset), vertical: .center(centerOffset)),
                            filling: .init(horizontal: .scaled(horizontalScale), vertical: .boxed(edges.vertical)))

        let resultRect = layout.layout(rect: itemRect, in: sourceRect)
        XCTAssertTrue(resultRect.origin.x == leftOffset)
        XCTAssertTrue(resultRect.origin.y == ((sourceRect.height - resultRect.height) / 2) + centerOffset)
        XCTAssertTrue(resultRect.width == sourceRect.width * horizontalScale)
        XCTAssertTrue(resultRect.height == sourceRect.height - edges.vertical)
        // print(resultRect)
    }

    func testPerformanceLayout() {
        let leftOffset: CGFloat = 15
        let centerOffset: CGFloat = 10
        let horizontalScale: CGFloat = 1.5
        let edges = EdgeInsets(top: 20, left: 0, bottom: 100, right: 0)

        let sourceRect = CGRect(x: 0, y: 0, width: 1000, height: 500)

        let layout = Layout(alignment: .init(horizontal: .left(leftOffset), vertical: .center(centerOffset)),
                            filling: .init(horizontal: .scaled(horizontalScale), vertical: .boxed(edges.vertical)))

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
        var view1 = CGRect.random(in: bounds)
        let view2 = CGRect.random(in: bounds)
        let alignment = Layout.Alignment.Vertical.top()

        alignment.formLayout(rect: &view1, in: view2)

        XCTAssertTrue(view1.minY == view2.minY)
    }

    func testTopAlignmentWithOffset() {
        var view1 = CGRect.random(in: bounds)
        let view2 = CGRect.random(in: bounds)
        let alignment = Layout.Alignment.Vertical.top(-10)

        alignment.formLayout(rect: &view1, in: view2)

        XCTAssertTrue(view1.minY + 10 == view2.minY)
    }

    func testTopAlignmentWithMultiplier() {
        var frame1 = CGRect.random(in: bounds)
        let frame2 = CGRect.random(in: bounds)
        let alignment = Layout.Alignment.Vertical.top(multiplier: 0.3)

        alignment.formLayout(rect: &frame1, in: frame2)

        XCTAssertTrue(frame1.minY == frame2.minY + (frame2.height * 0.3))
    }

    func testTopAlignmentWithSpace() {
        var frame1 = CGRect(x: 0, y: 0, width: 0, height: 20)
        let alignment = Layout.Alignment.Vertical.top(between: 0...10)

        let frame2 = CGRect(x: 20, y: 20, width: 0, height: .random(in: 40..<100))
        alignment.formLayout(rect: &frame1, in: frame2)
        XCTAssertEqual(frame1.minY, frame2.minY + 10)

        let frame3 = CGRect(x: 20, y: 10, width: 0, height: .random(in: 20..<30))
        alignment.formLayout(rect: &frame1, in: frame3)
        XCTAssertEqual(frame1.minY, frame3.minY + frame3.height - frame1.height)

        let frame4 = CGRect(x: 20, y: 0, width: 0, height: .random(in: 0..<20))
        alignment.formLayout(rect: &frame1, in: frame4)
        XCTAssertEqual(frame1.minY, frame4.minY)
    }

    func testBottomAlignment() {
        var view1 = CGRect.random(in: bounds)
        let view2 = CGRect.random(in: bounds)
        let alignment = Layout.Alignment.Vertical.bottom()

        alignment.formLayout(rect: &view1, in: view2)

        XCTAssertTrue(view1.maxY == view2.maxY)
    }

    func testBottomAlignmentWithOffset() {
        var view1 = CGRect.random(in: bounds)
        let view2 = CGRect.random(in: bounds)
        let alignment = Layout.Alignment.Vertical.bottom(10)

        alignment.formLayout(rect: &view1, in: view2)

        XCTAssertTrue(view1.maxY + 10 == view2.maxY)
    }

    func testBottomAlignmentWithMultiplier() {
        var frame1 = CGRect.random(in: bounds)
        let frame2 = CGRect.random(in: bounds)
        let alignment = Layout.Alignment.Vertical.bottom(multiplier: 0.3)

        alignment.formLayout(rect: &frame1, in: frame2)

        XCTAssertTrue(frame1.maxY == frame2.maxY - (frame2.height * 0.3))
    }

    func testBottomAlignmentWithSpace() {
        var frame1 = CGRect(x: 0, y: 0, width: 0, height: 20)
        let alignment = Layout.Alignment.Vertical.bottom(between: 0...10)

        let frame2 = CGRect(x: 20, y: 150, width: 0, height: .random(in: 40..<100))
        alignment.formLayout(rect: &frame1, in: frame2)
        XCTAssertEqual(frame1.maxY, frame2.maxY - 10)

        let frame3 = CGRect(x: 20, y: 2, width: 0, height: .random(in: 20..<30))
        alignment.formLayout(rect: &frame1, in: frame3)
        XCTAssertEqual(frame1.maxY, frame3.maxY - (frame3.height - frame1.height))

        let frame4 = CGRect(x: 20, y: 0, width: 0, height: .random(in: 0..<20))
        alignment.formLayout(rect: &frame1, in: frame4)
        XCTAssertEqual(frame1.maxY, frame4.maxY)
    }

    func testLeftAlignment() {
        var view1 = CGRect.random(in: bounds)
        let view2 = CGRect.random(in: bounds)
        let alignment = Layout.Alignment.Horizontal.left()

        alignment.formLayout(rect: &view1, in: view2)

        XCTAssertTrue(view1.minX == view2.minX)
    }

    func testLeftAlignmentWithOffset() {
        var view1 = CGRect.random(in: bounds)
        let view2 = CGRect.random(in: bounds)
        let alignment = Layout.Alignment.Horizontal.left(-10)

        alignment.formLayout(rect: &view1, in: view2)

        XCTAssertTrue(view1.minX + 10 == view2.minX)
    }

    func testLeftAlignmentWithMultiplier() {
        var frame1 = CGRect.random(in: bounds)
        let frame2 = CGRect.random(in: bounds)
        let alignment = Layout.Alignment.Horizontal.left(multiplier: 0.2)

        alignment.formLayout(rect: &frame1, in: frame2)

        XCTAssertTrue(frame1.minX == frame2.minX + (frame2.width * 0.2))
    }

    func testLeftAlignmentWithSpace() {
        var frame1 = CGRect(x: 0, y: 0, width: 20, height: 0)
        let alignment = Layout.Alignment.Horizontal.left(between: 0...10)

        let frame2 = CGRect(x: 20, y: 0, width: .random(in: 40..<100), height: 0)
        alignment.formLayout(rect: &frame1, in: frame2)
        XCTAssertEqual(frame1.minX, frame2.minX + 10)

        let frame3 = CGRect(x: 20, y: 0, width: .random(in: 20..<30), height: 0)
        alignment.formLayout(rect: &frame1, in: frame3)
        XCTAssertEqual(frame1.minX, frame3.minX + frame3.width - frame1.width)

        let frame4 = CGRect(x: 20, y: 0, width: .random(in: 0..<20), height: 0)
        alignment.formLayout(rect: &frame1, in: frame4)
        XCTAssertEqual(frame1.minX, frame4.minX)
    }

    func testRightAlignment() {
        var view1 = CGRect.random(in: bounds)
        let view2 = CGRect.random(in: bounds)
        let alignment = Layout.Alignment.Horizontal.right()

        alignment.formLayout(rect: &view1, in: view2)

        XCTAssertTrue(view1.maxX == view2.maxX)
    }

    func testRightAlignmentWithOffset() {
        var view1 = CGRect.random(in: bounds)
        let view2 = CGRect.random(in: bounds)
        let alignment = Layout.Alignment.Horizontal.right(10)

        alignment.formLayout(rect: &view1, in: view2)

        XCTAssertTrue(view1.maxX + 10 == view2.maxX)
    }

    func testRightAlignmentWithMultiplier() {
        var frame1 = CGRect.random(in: bounds)
        let frame2 = CGRect.random(in: bounds)
        let alignment = Layout.Alignment.Horizontal.right(multiplier: 0.2)

        alignment.formLayout(rect: &frame1, in: frame2)

        XCTAssertTrue(frame1.maxX == frame2.maxX - (frame2.width * 0.2))
    }

    func testRightAlignmentWithSpace() {
        var frame1 = CGRect(x: 0, y: 0, width: 20, height: 0)
        let alignment = Layout.Alignment.Horizontal.right(between: 0...10)

        let frame2 = CGRect(x: 20, y: 0, width: .random(in: 40..<100), height: 0)
        alignment.formLayout(rect: &frame1, in: frame2)
        XCTAssertEqual(frame1.maxX, frame2.maxX - 10)

        let frame3 = CGRect(x: 20, y: 0, width: .random(in: 20..<30), height: 0)
        alignment.formLayout(rect: &frame1, in: frame3)
        XCTAssertEqual(frame1.maxX, frame3.maxX - (frame3.width - frame1.width))

        let frame4 = CGRect(x: 20, y: 0, width: .random(in: 0..<20), height: 0)
        alignment.formLayout(rect: &frame1, in: frame4)
        XCTAssertEqual(frame1.maxX, frame4.maxX)
    }
}

// MARK: Filling

extension Tests {
    func testFillingFixed() {
        let widthConstant: CGFloat = 45.7
        let heightConstant: CGFloat = 99.0
        var rect1 = CGRect.random(in: bounds)
        var rect2 = CGRect.random(in: bounds)
        let vertical = Layout.Filling.Vertical.fixed(heightConstant)
        let horizontal = Layout.Filling.Horizontal.fixed(widthConstant)

        vertical.formLayout(rect: &rect1, in: bounds) // second parameter has no effect in this case
        horizontal.formLayout(rect: &rect2, in: bounds) // second parameter has no effect in this case

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
        vertical.formLayout(rect: &resultRect1, in: rect2)
        horizontal.formLayout(rect: &resultRect2, in: rect1)

        XCTAssertTrue(resultRect1.height == rect2.height * heightScale)
        XCTAssertTrue(resultRect2.width == rect1.width * widthScale)
    }

    func testFillingBoxed() {
        let box = EdgeInsets(top: 20, left: 20, bottom: -30, right: -15)
        let rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)
        let vertical = Layout.Filling.Vertical.boxed(box.vertical)
        let horizontal = Layout.Filling.Horizontal.boxed(box.horizontal)

        var resultRect1 = rect1
        var resultRect2 = rect2
        vertical.formLayout(rect: &resultRect1, in: rect2)
        horizontal.formLayout(rect: &resultRect2, in: rect1)

        XCTAssertTrue(resultRect1.height == max(0, rect2.height - box.vertical))
        XCTAssertTrue(resultRect2.width == max(0, rect1.width - box.horizontal))
    }

    func testFillingBetween() {
        var rect = CGRect.zero
        let vertical = Layout.Filling.Vertical.between(10...20)
        let horizontal = Layout.Filling.Horizontal.between(10...40)

        let height1 = CGRect(x: 20, y: 0, width: 0, height: .random(in: 40..<100))
        let width1 = CGRect(x: 20, y: 0, width: .random(in: 40..<100), height: 0)
        vertical.formLayout(rect: &rect, in: height1)
        XCTAssertEqual(rect.height, 20)
        horizontal.formLayout(rect: &rect, in: width1)
        XCTAssertEqual(rect.width, 40)

        let height2 = CGRect(x: 20, y: 0, width: 0, height: .random(in: 10..<20))
        let width2 = CGRect(x: 20, y: 0, width: .random(in: 20..<30), height: 0)
        vertical.formLayout(rect: &rect, in: height2)
        XCTAssertEqual(rect.height, height2.height)
        horizontal.formLayout(rect: &rect, in: width2)
        XCTAssertEqual(rect.width, width2.width)

        let height3 = CGRect(x: 20, y: 0, width: 0, height: .random(in: 0..<10))
        let width3 = CGRect(x: 20, y: 0, width: .random(in: 0..<10), height: 0)
        vertical.formLayout(rect: &rect, in: height3)
        XCTAssertEqual(rect.height, 10)
        horizontal.formLayout(rect: &rect, in: width3)
        XCTAssertEqual(rect.width, 10)
    }

    func testFillingUpTo() {
        var rect = CGRect.zero
        let vertical = Layout.Filling.Vertical.upTo(20)
        let horizontal = Layout.Filling.Horizontal.upTo(40)

        let height1 = CGRect(x: 20, y: 0, width: 0, height: .random(in: 40..<100))
        let width1 = CGRect(x: 20, y: 0, width: .random(in: 40..<100), height: 0)
        vertical.formLayout(rect: &rect, in: height1)
        XCTAssertEqual(rect.height, 20)
        horizontal.formLayout(rect: &rect, in: width1)
        XCTAssertEqual(rect.width, 40)

        let height2 = CGRect(x: 20, y: 0, width: 0, height: .random(in: 10..<20))
        let width2 = CGRect(x: 20, y: 0, width: .random(in: 20..<30), height: 0)
        vertical.formLayout(rect: &rect, in: height2)
        XCTAssertEqual(rect.height, height2.height)
        horizontal.formLayout(rect: &rect, in: width2)
        XCTAssertEqual(rect.width, width2.width)
    }

    func testFillingFrom() {
        var rect = CGRect.zero
        let vertical = Layout.Filling.Vertical.from(20)
        let horizontal = Layout.Filling.Horizontal.from(40)

        let height1 = CGRect(x: 20, y: 0, width: 0, height: .random(in: 40..<100))
        let width1 = CGRect(x: 20, y: 0, width: .random(in: 50..<100), height: 0)
        vertical.formLayout(rect: &rect, in: height1)
        XCTAssertEqual(rect.height, height1.height)
        horizontal.formLayout(rect: &rect, in: width1)
        XCTAssertEqual(rect.width, width1.width)

        let height2 = CGRect(x: 20, y: 0, width: 0, height: .random(in: 10..<20))
        let width2 = CGRect(x: 20, y: 0, width: .random(in: 20..<30), height: 0)
        vertical.formLayout(rect: &rect, in: height2)
        XCTAssertEqual(rect.height, 20)
        horizontal.formLayout(rect: &rect, in: width2)
        XCTAssertEqual(rect.width, 40)
    }
}

// MARK: LayoutAnchor

extension Tests {
    func testAnchorBottomAlign() {
        let outer = Bottom.align(by: .outer)
        var rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)

        let inner = Bottom.align(by: .inner)
        var rect3 = CGRect.random(in: bounds)
        let rect4 = CGRect.random(in: bounds)

        outer.formConstrain(sourceRect: &rect1, by: rect2)
        inner.formConstrain(sourceRect: &rect3, by: rect4)

        XCTAssertTrue(rect1.minY == rect2.maxY)
        XCTAssertTrue(rect3.maxY == rect4.maxY)
    }
    func testAnchorBottomLimit() {
        let outer = Bottom.limit(on: .outer)
        let rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)
        let isRect1AboveBottomRect2 = rect1.maxY <= rect2.maxY
        let isRect1BelowBottomRect2 = rect1.minY >= rect2.maxY

        let inner = Bottom.limit(on: .inner)
        let rect3 = CGRect.random(in: bounds)
        let rect4 = CGRect.random(in: bounds)
        let isRect3AboveBottomRect4 = rect3.maxY <= rect4.maxY
        let isRect3BelowBottomRect4 = rect3.minY >= rect4.maxY

        var resultRect1 = rect1
        var resultRect3 = rect3
        outer.formConstrain(sourceRect: &resultRect1, by: rect2)
        inner.formConstrain(sourceRect: &resultRect3, by: rect4)

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
        let outer = Bottom.pull(from: .outer)
        let rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)
        let isBottomRect1BelowBottomRect2 = rect1.maxY > rect2.maxY

        let inner = Bottom.pull(from: .inner)
        let rect3 = CGRect.random(in: bounds)
        let rect4 = CGRect.random(in: bounds)
        let isTopRect3AboveBottomRect4 = rect3.minY < rect4.maxY

        var resultRect1 = rect1
        var resultRect3 = rect3
        outer.formConstrain(sourceRect: &resultRect1, by: rect2)
        inner.formConstrain(sourceRect: &resultRect3, by: rect4)

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
        let outer = Right.align(by: .outer)
        var rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)

        let inner = Right.align(by: .inner)
        var rect3 = CGRect.random(in: bounds)
        let rect4 = CGRect.random(in: bounds)

        outer.formConstrain(sourceRect: &rect1, by: rect2)
        inner.formConstrain(sourceRect: &rect3, by: rect4)

        XCTAssertTrue(rect1.minX == rect2.maxX)
        XCTAssertTrue(rect3.maxX == rect4.maxX)
    }
    func testAnchorRightLimit() {
        let outer = Right.limit(on: .outer)
        let rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)
        let isRect1BeforeRightRect2 = rect1.maxX <= rect2.maxX
        let isRect1AfterRightRect2 = rect1.minX >= rect2.maxX

        let inner = Right.limit(on: .inner)
        let rect3 = CGRect.random(in: bounds)
        let rect4 = CGRect.random(in: bounds)
        let isRect3BeforeRightRect4 = rect3.maxX <= rect4.maxX
        let isRect3AfterRightRect4 = rect3.minX >= rect4.maxX

        var resultRect1 = rect1
        var resultRect3 = rect3
        outer.formConstrain(sourceRect: &resultRect1, by: rect2)
        inner.formConstrain(sourceRect: &resultRect3, by: rect4)

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
        let outer = Right.pull(from: .outer)
        let rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)
        let isRightRect1AfterRightRect2 = rect1.maxX > rect2.maxX

        let inner = Right.pull(from: .inner)
        let rect3 = CGRect.random(in: bounds)
        let rect4 = CGRect.random(in: bounds)
        let isLeftRect3BeforeRightRect4 = rect3.minX < rect4.maxX

        var resultRect1 = rect1
        var resultRect3 = rect3
        outer.formConstrain(sourceRect: &resultRect1, by: rect2)
        inner.formConstrain(sourceRect: &resultRect3, by: rect4)

        XCTAssertTrue(resultRect1.minX == rect2.maxX, "\((resultRect1, rect1, rect2))")
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
        let outer = Left.align(by: .outer)
        var rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)

        let inner = Left.align(by: .inner)
        var rect3 = CGRect.random(in: bounds)
        let rect4 = CGRect.random(in: bounds)

        outer.formConstrain(sourceRect: &rect1, by: rect2)
        inner.formConstrain(sourceRect: &rect3, by: rect4)

        XCTAssertTrue(rect1.maxX == rect2.minX)
        XCTAssertTrue(rect3.minX == rect4.minX)
    }
    func testAnchorLeftLimit() {
        let outer = Left.limit(on: .outer)
        let rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)
        let isRect1BeforeLeftRect2 = rect1.maxX <= rect2.minX
        let isRect1AfterLeftRect2 = rect1.minX >= rect2.minX

        let inner = Left.limit(on: .inner)
        let rect3 = CGRect.random(in: bounds)
        let rect4 = CGRect.random(in: bounds)
        let isRect3BeforeLeftRect4 = rect3.maxX <= rect4.minX
        let isRect3AfterLeftRect4 = rect3.minX >= rect4.minX

        var resultRect1 = rect1
        var resultRect3 = rect3
        outer.formConstrain(sourceRect: &resultRect1, by: rect2)
        inner.formConstrain(sourceRect: &resultRect3, by: rect4)

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
        let outer = Left.pull(from: .outer)
        let rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)
        let isLeftRect1BeforeLeftRect2 = rect1.left < rect2.left

        let inner = Left.pull(from: .inner)
        let rect3 = CGRect.random(in: bounds)
        let rect4 = CGRect.random(in: bounds)
        let isRightRect3BeforeLeftRect4 = rect3.right < rect4.left

        var resultRect1 = rect1
        var resultRect3 = rect3
        outer.formConstrain(sourceRect: &resultRect1, by: rect2)
        inner.formConstrain(sourceRect: &resultRect3, by: rect4)

        XCTAssertTrue(resultRect1.maxX == rect2.minX)
        if isLeftRect1BeforeLeftRect2 {
            XCTAssertTrue(resultRect1.width == rect2.minX - rect1.minX)
        }
        XCTAssertTrue(resultRect3.minX == rect4.minX)
        XCTAssertTrue(resultRect3.width == max(0, rect3.maxX - rect4.minX))
        if isRightRect3BeforeLeftRect4 {
            XCTAssertTrue(resultRect3.right == rect4.left)
        }
    }

    func testAnchorTopAlign() {
        let outer = Top.align(by: .outer)
        var rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)

        let inner = Top.align(by: .inner)
        var rect3 = CGRect.random(in: bounds)
        let rect4 = CGRect.random(in: bounds)

        outer.formConstrain(sourceRect: &rect1, by: rect2)
        inner.formConstrain(sourceRect: &rect3, by: rect4)

        XCTAssertTrue(rect1.bottom == rect2.top)
        XCTAssertTrue(rect3.top == rect4.top)
    }
    func testAnchorTopLimit() {
        let outer = Top.limit(on: .outer)
        let rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)
        let isRect1AboveTopRect2 = rect1.bottom <= rect2.top
        let isRect1BelowTopRect2 = rect1.top >= rect2.top

        let inner = Top.limit(on: .inner)
        let rect3 = CGRect.random(in: bounds)
        let rect4 = CGRect.random(in: bounds)
        let isRect3AboveTopRect4 = rect3.bottom <= rect4.top
        let isRect3BelowTopRect4 = rect3.top >= rect4.top

        var resultRect1 = rect1
        var resultRect3 = rect3
        outer.formConstrain(sourceRect: &resultRect1, by: rect2)
        inner.formConstrain(sourceRect: &resultRect3, by: rect4)

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
        let outer = Top.pull(from: .outer)
        let rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)
        let isTopRect1AboveTopRect2 = rect1.top < rect2.top

        let inner = Top.pull(from: .inner)
        let rect3 = CGRect.random(in: bounds)
        let rect4 = CGRect.random(in: bounds)
        let isBottomRect3AboveTopRect4 = rect3.bottom < rect4.top

        var resultRect1 = rect1
        var resultRect3 = rect3
        outer.formConstrain(sourceRect: &resultRect1, by: rect2)
        inner.formConstrain(sourceRect: &resultRect3, by: rect4)

        XCTAssertTrue(resultRect1.maxY == rect2.minY)
        if isTopRect1AboveTopRect2 {
            XCTAssertTrue(resultRect1.height == rect2.minY - rect1.minY)
        }
        XCTAssertTrue(resultRect3.minY == rect4.minY)
        XCTAssertTrue(resultRect3.height == max(0, rect3.maxY - rect4.minY))
        if isBottomRect3AboveTopRect4 {
            XCTAssertTrue(resultRect3.maxY == rect4.minY)
        }
    }

    func testCenterToCenterAnchor() {
        let centerAnchor = Center.align(by: .center)
        let rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)

        let resultRect1 = centerAnchor.constrained(sourceRect: rect1, by: rect2)

        XCTAssertTrue(resultRect1.midX == rect2.midX)
        XCTAssertTrue(resultRect1.midY == rect2.midY)
    }

    func testCenterToOriginAnchor() {
        let centerAnchor = Center.align(by: .origin)
        let rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)

        let resultRect1 = centerAnchor.constrained(sourceRect: rect1, by: rect2)

        XCTAssertTrue(resultRect1.minX == rect2.midX)
        XCTAssertTrue(resultRect1.minY == rect2.midY)
    }

    func testHeightAnchor() {
        let heightAnchor = Size.height()
        let rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)

        XCTAssertFalse(rect1.height == rect2.height)

        let resultRect1 = heightAnchor.constrained(sourceRect: rect1, by: rect2)

        XCTAssertTrue(resultRect1.height == rect2.height)
    }

    func testWidthAnchor() {
        let widthAnchor = Size.width(2)
        let rect1 = CGRect.random(in: bounds)
        let rect2 = CGRect.random(in: bounds)

        XCTAssertFalse(rect1.width == rect2.width)

        let resultRect1 = widthAnchor.constrained(sourceRect: rect1, by: rect2)

        XCTAssertTrue(resultRect1.width == rect2.width * 2)
    }

    func testInsetAnchor() {
        let insets = EdgeInsets(top: -20, left: 0, bottom: 10, right: 5)
        let insetAnchor = Inset(insets)
        let rect1 = CGRect.random(in: bounds)

        let resultRect1 = insetAnchor.constrained(sourceRect: rect1, by: .zero) // second rect has no effect

        XCTAssertTrue(EdgeInsetsInsetRect(rect1, insets) == resultRect1)
    }
}

// MARK: Snapshot

extension Tests {
    func testSnapshotEqualLayoutDirectly() {
        let superview = View(frame: bounds)
        let initialFrames = (0..<5).map { _ in CGRect.random(in: bounds) }
        let subviews = initialFrames.map(View.init)
        subviews.forEach(View.addSubview(superview))
        let blocks = (0..<5).map { i in
            subviews[i].layoutBlock(with: Layout(x: .center(), y: .top(2), width: .scaled(0.9), height: .fixed(20)),
                                    constraints: i == 0 ? [] : [subviews[i - 1].layoutConstraint(for: [.bottom(.align(by: .outer))])])
        }
        let scheme = LayoutScheme(blocks: blocks)

        let snapshot = scheme.snapshot(for: bounds)

        XCTAssertFalse(snapshot.childSnapshots.map { $0.frame } == subviews.map { $0.frame })

        scheme.layout()

        XCTAssertTrue(snapshot.childSnapshots.map { $0.frame } == subviews.map { $0.frame })
    }

    func testApplyingSnapshotEqualLayoutDirectly() {
        var framesAfterLayoutDirectly: [CGRect]!
        var framesAfterApplyingSnapshot: [CGRect]!
        let initialFrames = (0..<5).map { _ in CGRect.random(in: bounds) }

        for i in 0..<2 {
            let superview = View(frame: bounds)
            let subviews = initialFrames.map(View.init)
            subviews.forEach(View.addSubview(superview))

            let blocks = (0..<5).map { i in
                subviews[i].layoutBlock(with: Layout(x: .center(), y: .top(2), width: .scaled(0.9), height: .fixed(20)),
                                        constraints: i == 0 ? [] : [subviews[i - 1].layoutConstraint(for: [.bottom(.align(by: .outer))])])
            }

            let scheme = LayoutScheme(blocks: blocks)

            if i == 0 {
                scheme.layout()
                framesAfterLayoutDirectly = subviews.map { $0.frame }
            } else {
                let snapshot = scheme.snapshot(for: bounds)
                scheme.apply(snapshot: snapshot)
                framesAfterApplyingSnapshot = subviews.map { $0.frame }
            }
        }

        XCTAssertTrue(framesAfterLayoutDirectly == framesAfterApplyingSnapshot)
    }

    func testCurrentSnapshotEqualLayoutDirectly() {
        let superview = View(frame: bounds)
        let initialFrames = (0..<5).map { _ in CGRect.random(in: bounds) }
        let subviews = initialFrames.map(View.init)
        subviews.forEach(View.addSubview(superview))
        let blocks = (0..<5).map { i in
            subviews[i].layoutBlock(with: Layout(x: .center(), y: .top(2), width: .scaled(0.9), height: .fixed(20)),
                                    constraints: i == 0 ? [] : [subviews[i - 1].layoutConstraint(for: [.bottom(.align(by: .outer))])])
        }
        let scheme = LayoutScheme(blocks: blocks)

        scheme.layout()

        let snapshot = scheme.currentSnapshot

        XCTAssertTrue(snapshot.childSnapshots.map { $0.frame } == subviews.map { $0.frame })
    }
}

// MARK: LayoutCoordinateSpace

extension Tests {
    func testCoordinateSpacePointLayoutGuide() {
        let superview = View(frame: bounds.insetBy(dx: 100, dy: 100))
        let guide = LayoutGuide<Layer>(frame: CGRect(x: 20, y: 10, width: 40, height: 60))
        #if os(macOS)
        superview.wantsLayer = true
        superview.layer!.add(layoutGuide: guide)
        #else
        superview.layer.add(layoutGuide: guide)
        #endif

        #if os(macOS)
        let converted = superview.layer!.convert(point: CGPoint(x: 10, y: -5), from: guide)
        let converted2 = guide.convert(point: CGPoint(x: 150, y: 0), from: superview.layer!)
        #else
        let converted = superview.layer.convert(point: CGPoint(x: 10, y: -5), from: guide)
        let converted2 = guide.convert(point: CGPoint(x: 150, y: 0), from: superview.layer)
        #endif

        XCTAssertTrue(converted.x == 30)
        XCTAssertTrue(converted.y == 5)

        XCTAssertTrue(converted2.x == 130)
        XCTAssertTrue(converted2.y == -10)
    }
#if os(iOS)
    func testCoordinateSpaceCGRect() {
        let window = UIWindow(frame: bounds)
        let superview = UIScrollView(frame: bounds.insetBy(dx: 100, dy: 100))
        window.addSubview(superview)
        superview.contentSize = bounds.size
        superview.contentOffset.x = 150
        let view = ViewPlaceholder(frame: CGRect(x: 20, y: 10, width: 40, height: 60))
        superview.add(layoutGuide: view)

        let converted = view.convert(rect: CGRect(x: 10, y: -5, width: 20, height: 10), to: window)
        let converted2 = view.convert(rect: CGRect(x: 150, y: 0, width: 30, height: 20), from: superview)

        XCTAssertTrue(converted.origin.x == -20)
        XCTAssertTrue(converted.origin.y == 105)

        XCTAssertTrue(converted2.origin.x == 130)
        XCTAssertTrue(converted2.origin.y == -10)
    }
    /// UILayoutGuide has valid layoutFrame only in layoutSubviews method.
    func testCoordinateSpacePointUILayoutGuide() {
        class LayoutView: UIView {
            var layout: (() -> Void)?
            override func layoutSubviews() {
                super.layoutSubviews()
                layout?()
            }
        }

        let superview = LayoutView(frame: bounds.insetBy(dx: 100, dy: 100))
        let guide = UILayoutGuide()
        superview.translatesAutoresizingMaskIntoConstraints = false
        superview.addLayoutGuide(guide)
        NSLayoutConstraint.activate([
            guide.leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: 20),
            guide.topAnchor.constraint(equalTo: superview.topAnchor, constant: 10),
            guide.heightAnchor.constraint(equalToConstant: 60),
            guide.widthAnchor.constraint(equalToConstant: 40)
        ])

        var converted: CGPoint = .zero
        var converted2: CGPoint = .zero
        superview.layout = {
            converted = superview.layer.convert(point: CGPoint(x: 10, y: -5), from: guide)
            converted2 = guide.convert(point: CGPoint(x: 150, y: 0), from: superview.layer)
        }
        superview.setNeedsLayout()
        superview.layoutIfNeeded()

        XCTAssertTrue(converted.x == 30)
        XCTAssertTrue(converted.y == 5)

        XCTAssertTrue(converted2.x == 130)
        XCTAssertTrue(converted2.y == -10)
    }
    func testLayoutGuideCoordinateConverting() {
        let guideSuperview = UIView(frame: bounds.insetBy(dx: 100, dy: 100))
        let guide = LayoutGuide<UIView>(frame: CGRect(x: 0, y: 0, width: 100, height: 200))
        guideSuperview.add(layoutGuide: guide)

        let convertedPointTo = guide.convert(CGPoint(x: 10, y: 10), to: UIScreen.main.coordinateSpace)
        let convertedPointFrom = guide.convert(CGPoint(x: 10, y: 10), from: UIScreen.main.coordinateSpace)
        let convertedRectTo = guide.convert(CGRect(x: 10, y: 10, width: 20, height: 20), to: UIScreen.main.coordinateSpace)
        let convertedRectFrom = guide.convert(CGRect(x: 10, y: 10, width: 20, height: 20), from: UIScreen.main.coordinateSpace)

        XCTAssertTrue(convertedPointTo.x == 110)
        XCTAssertTrue(convertedPointTo.y == 110)
        XCTAssertTrue(convertedRectTo.origin.x == 110)
        XCTAssertTrue(convertedRectTo.origin.y == 110)

        XCTAssertTrue(convertedPointFrom.x == -90)
        XCTAssertTrue(convertedPointFrom.y == -90)
        XCTAssertTrue(convertedRectFrom.origin.x == -90)
        XCTAssertTrue(convertedRectFrom.origin.y == -90)
    }
#endif
}

// Container

#if os(iOS)
extension Tests {
    func testEnterPoint() {
        let window = Window(frame: CGRect(x: 230, y: 305, width: 200, height: 100))
        let view = View(frame: .zero)

        let point = EnterPoint<View, Window>(child: view)
        point.add(to: window)

        XCTAssertTrue(window.subviews.contains(where: { $0 === view }))
        XCTAssertTrue(window.layer.sublayers?.contains(where: { $0 === view.layer }) == true)
    }
    func testChildren() {
        let window = Window(frame: CGRect(x: 230, y: 305, width: 200, height: 100))
        let view = View(frame: .zero)

        window.children.add(view)

        XCTAssertTrue(window.subviews.contains(where: { $0 === view }))
        XCTAssertTrue(window.layer.sublayers?.contains(where: { $0 === view.layer }) == true)
    }
}
#endif

// MARK: Stack scheme, layout guide

extension Tests {
    func testLayoutDistribution() {
        let frames = (0..<5).map { _ in CGRect.random(in: bounds) }
        var previous: CGRect?
        let distributedFrames = distributeFromTrailing(rects: frames, in: bounds, along: CGRectAxis.vertical, spacing: 2)

        var iterator = distributedFrames.makeIterator()
        previous = iterator.next()
        XCTAssertTrue(previous!.maxY == bounds.maxY)
        while let next = iterator.next() {
            XCTAssertTrue(previous!.top == next.bottom + 2)

            previous = next
        }
    }
    func testLayoutDistributionFunc1Performance() {
        func distribute(rectsBy pointer: UnsafeMutablePointer<CGRect>, count: Int, in sourceRect: CGRect) {
            let size = sourceRect.width / CGFloat(count)
            for i in (0..<count) {
                pointer[i].origin.x = CGFloat(i) * size
                pointer[i].size.width = size
            }
        }
        let count = 2
        let pointer = UnsafeMutablePointer<CGRect>.allocate(capacity: count)
        let rects: [CGRect] = [.zero, .zero]
        pointer.initialize(from: rects, count: count)
        self.measure {
            distribute(rectsBy: pointer, count: count, in: CGRect(x: 0, y: 0, width: 200, height: 200))
        }
        print((0..<count).map { pointer[$0] })
    }
    func testLayoutDistributionFunc2Performance() {
        func distribute(rects: inout [UnsafeMutablePointer<CGRect>], in sourceRect: CGRect) {
            let count = CGFloat(rects.count)
            let size = sourceRect.width / count
            for (i, pointer) in rects.enumerated() {
                pointer.pointee.origin.x = CGFloat(i) * size
                pointer.pointee.size.width = size
            }
        }
        var rect1: CGRect = .zero
        var rect2: CGRect = .zero
        var rects: [UnsafeMutablePointer<CGRect>] = [
            UnsafeMutablePointer<CGRect>(&rect1), 
            UnsafeMutablePointer<CGRect>(&rect2)
        ]
        self.measure {
            distribute(rects: &rects, in: CGRect(x: 0, y: 0, width: 200, height: 200))
        }
        print(rects.map { $0.pointee })
    }
    func testStackLayoutScheme() {
        let views = (0..<5).map { _ in View(frame: .random(in: bounds)) }
        var stack = StackLayoutScheme(items: { views })
//        stack.distribution = .fromRight(spacing: 0)
        stack.spacing = .equal(0)
        stack.direction = .fromLeading
        stack.alignment = .center()
//        stack.filling = .custom(Layout.Filling(horizontal: .fixed(20), vertical: .scaled(1)))
        stack.filling = .equal(20)

        stack.layout(in: bounds)

        XCTAssertTrue(Int(stack.currentSnapshot.frame.width) == views.count * 20)
    }
    #if os(iOS)
    func testStackLayoutGuideSizeThatFits() {
        let stackGuide = StackLayoutGuide<View>(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 200)))
//        stackGuide.scheme.filling = .custom(Layout.Filling(horizontal: .fixed(30), vertical: .scaled(1)))
//        stackGuide.scheme.distribution = .fromLeft(spacing: 5)
        stackGuide.scheme.filling = .equal(30)
        stackGuide.scheme.spacing = .equal(5)

//        stackGuide.addArrangedElement(View(frame: .random(in: stackGuide.bounds)))
//        stackGuide.addArrangedElement(View(frame: .random(in: stackGuide.bounds)))
//        stackGuide.addArrangedElement(View(frame: .random(in: stackGuide.bounds)))
        stackGuide.views.add(View(frame: .random(in: stackGuide.bounds)))
        stackGuide.views.add(View(frame: .random(in: stackGuide.bounds)))
        stackGuide.views.add(View(frame: .random(in: stackGuide.bounds)))

        XCTAssertTrue(CGSize(width: 100, height: 200) == stackGuide.sizeThatFits(stackGuide.bounds.size))
    }
    func testStackLayoutGuideAddRemoveLayoutItems() {
        let view = View()
        let stackGuide = StackLayoutGuide<View>(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 200)))
        view.add(layoutGuide: stackGuide)

        let subview = View(frame: .random(in: stackGuide.bounds))
        stackGuide.addArrangedElement(subview)
        let sublayer = Layer(frame: .random(in: stackGuide.bounds))
        stackGuide.addArrangedElement(sublayer)
        let layoutGuide = LayoutGuide<Layer>(frame: .random(in: stackGuide.bounds))
        stackGuide.addArrangedElement(layoutGuide)

        XCTAssertTrue(subview.superElement === view)
        XCTAssertTrue(sublayer.superElement === view.layer)
        XCTAssertTrue(layoutGuide.ownerElement === view.layer)

        stackGuide.removeArrangedElement(subview)
        stackGuide.removeArrangedElement(sublayer)
        stackGuide.removeArrangedElement(layoutGuide)

        XCTAssertNil(subview.superElement)
        XCTAssertNil(sublayer.superElement)
        XCTAssertNil(layoutGuide.ownerElement)
    }
    func testRemoveStackLayoutFromSuperItem() {
        let view = View()
        let stackGuide = StackLayoutGuide<View>(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 200)))
        view.add(layoutGuide: stackGuide)

        let subview = View(frame: .random(in: stackGuide.bounds))
        stackGuide.addArrangedElement(subview)
        let sublayer = Layer(frame: .random(in: stackGuide.bounds))
        stackGuide.addArrangedElement(sublayer)
        let layoutGuide = LayoutGuide<Layer>(frame: .random(in: stackGuide.bounds))
        stackGuide.addArrangedElement(layoutGuide)

        stackGuide.removeFromSuperElement()

        XCTAssertNil(subview.superElement)
        XCTAssertNil(sublayer.superElement)
        XCTAssertNil(layoutGuide.ownerElement)
    }
    #endif
}

// MARK: Baseline

#if os(iOS)
extension Tests {
    func testTextPresented() {
        let window = Window(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        let view = View(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
        let label = Label(frame: CGRect(x: 0, y: 100, width: 200, height: 50))
        window.addSubview(view)
        window.addSubview(label)

        let viewLayout = view.layoutBlock(constraints: [label.baselineLayoutConstraint(for: [.bottom(.align(by: .inner))])])

        viewLayout.layout()

        XCTAssertEqual(view.frame.maxY, label.baselineElement.frame.maxY)
    }

    func testTextPresented2() {
        let window = Window(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        let label1 = Label(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
        let label2 = Label(frame: CGRect(x: 0, y: 100, width: 200, height: 50))
        window.addSubview(label1)
        window.addSubview(label2)

        let label1Layout = label1.baselineElement.layoutBlock(constraints: [label2.baselineLayoutConstraint(for: [.top(.align(by: .inner))])])

        label1Layout.layout()

        XCTAssertEqual(label1.baselineElement.frame.maxY, label2.baselineElement.frame.maxY)
    }
}
#endif

// MARK: Measures

#if os(iOS)
extension Tests {
    func testCoordinateSpacePerformance() {
        let window = UIWindow(frame: bounds)
        let superview = UIScrollView(frame: bounds.insetBy(dx: 100, dy: 100))
        window.addSubview(superview)
        superview.contentSize = bounds.size
        superview.contentOffset.x = 150
        let view = UIView(frame: CGRect(x: 20, y: 10, width: 40, height: 60))
        superview.addSubview(view)

        self.measure {
            _ = view.convert(rect: CGRect(x: 10, y: -5, width: 20, height: 10), to: window)
            _ = view.convert(rect: CGRect(x: 150, y: 0, width: 30, height: 20), from: superview)
        }
    }
}
#endif

// MARK: RectAxis

extension Tests {
    func testLayoutWorkspaceBeforeLeadingAlign() {
        let leftAlign = LayoutWorkspace.Before.Align(axis: CGRectAxis.horizontal, anchor: CGRectAxisAnchor.leading)
        let topAlign = LayoutWorkspace.Before.Align(axis: CGRectAxis.vertical, anchor: CGRectAxisAnchor.leading)
        let rect1 = CGRect.random(in: bounds)
        var rect2 = CGRect.random(in: bounds)

        leftAlign.formConstrain(sourceRect: &rect2, by: rect1)
        topAlign.formConstrain(sourceRect: &rect2, by: rect1)

        XCTAssertTrue(rect2.right == rect1.left)
        XCTAssertTrue(rect2.bottom == rect1.top)
    }
    func testLayoutWorkspaceAfterLeadingAlign() {
        let leftAlign = LayoutWorkspace.After.Align(axis: CGRectAxis.horizontal, anchor: CGRectAxisAnchor.leading)
        let topAlign = LayoutWorkspace.After.Align(axis: CGRectAxis.vertical, anchor: CGRectAxisAnchor.leading)
        let rect1 = CGRect.random(in: bounds)
        var rect2 = CGRect.random(in: bounds)

        leftAlign.formConstrain(sourceRect: &rect2, by: rect1)
        topAlign.formConstrain(sourceRect: &rect2, by: rect1)

        XCTAssertTrue(rect2.left == rect1.left)
        XCTAssertTrue(rect2.top == rect1.top)
    }
    func testLayoutWorkspaceBeforeTrailingAlign() {
        let rightAlign = LayoutWorkspace.Before.Align(axis: CGRectAxis.horizontal, anchor: CGRectAxisAnchor.trailing)
        let bottomAlign = LayoutWorkspace.Before.Align(axis: CGRectAxis.vertical, anchor: CGRectAxisAnchor.trailing)
        let rect1 = CGRect.random(in: bounds)
        var rect2 = CGRect.random(in: bounds)

        rightAlign.formConstrain(sourceRect: &rect2, by: rect1)
        bottomAlign.formConstrain(sourceRect: &rect2, by: rect1)

        XCTAssertTrue(rect2.right == rect1.right)
        XCTAssertTrue(rect2.bottom == rect1.bottom)
    }
    func testLayoutWorkspaceAfterTrailingAlign() {
        let rightAlign = LayoutWorkspace.After.Align(axis: CGRectAxis.horizontal, anchor: CGRectAxisAnchor.trailing)
        let bottomAlign = LayoutWorkspace.After.Align(axis: CGRectAxis.vertical, anchor: CGRectAxisAnchor.trailing)
        let rect1 = CGRect.random(in: bounds)
        var rect2 = CGRect.random(in: bounds)

        rightAlign.formConstrain(sourceRect: &rect2, by: rect1)
        bottomAlign.formConstrain(sourceRect: &rect2, by: rect1)

        XCTAssertTrue(rect2.left == rect1.right)
        XCTAssertTrue(rect2.top == rect1.bottom)
    }
}

// MARK: Beta testing, improvements

extension Tests {
    func testLazyFilter() {
        let numbers = 0..<10

        var counter = 0
        numbers.lazy.filter {
            counter += 1
            return $0 % 2 == 0
        }.forEach {
            XCTAssertFalse(counter == numbers.count)
            print($0)
        }
    }
}

extension Tests {
    static var allTests: [(String, (Tests) -> () -> ())] {
        var tests = [
            ("testLayout", testLayout),
            ("testPerformanceLayout", testPerformanceLayout),
            ("testTopAlignment", testTopAlignment),
            ("testTopAlignmentWithOffset", testTopAlignmentWithOffset),
            ("testBottomAlignment", testBottomAlignment),
            ("testBottomAlignmentWithOffset", testBottomAlignmentWithOffset),
            ("testLeftAlignment", testLeftAlignment),
            ("testLeftAlignmentWithOffset", testLeftAlignmentWithOffset),
            ("testRightAlignment", testRightAlignment),
            ("testRightAlignmentWithOffset", testRightAlignmentWithOffset),
            ("testFillingFixed", testFillingFixed),
            ("testFillingScaled", testFillingScaled),
            ("testFillingBoxed", testFillingBoxed),
            ("testAnchorBottomAlign", testAnchorBottomAlign),
            ("testAnchorBottomLimit", testAnchorBottomLimit),
            ("testAnchorBottomPull", testAnchorBottomPull),
            ("testAnchorRightAlign", testAnchorRightAlign),
            ("testAnchorRightLimit", testAnchorRightLimit),
            ("testAnchorRightPull", testAnchorRightPull),
            ("testAnchorLeftAlign", testAnchorLeftAlign),
            ("testAnchorLeftLimit", testAnchorLeftLimit),
            ("testAnchorLeftPull", testAnchorLeftPull),
            ("testAnchorTopAlign", testAnchorTopAlign),
            ("testAnchorTopLimit", testAnchorTopLimit),
            ("testAnchorTopPull", testAnchorTopPull),
            ("testCenterToCenterAnchor", testCenterToCenterAnchor),
            ("testCenterToOriginAnchor", testCenterToOriginAnchor),
            ("testHeightAnchor", testHeightAnchor),
            ("testWidthAnchor", testWidthAnchor),
            ("testInsetAnchor", testInsetAnchor),
            ("testSnapshotEqualLayoutDirectly", testSnapshotEqualLayoutDirectly),
            ("testApplyingSnapshotEqualLayoutDirectly", testApplyingSnapshotEqualLayoutDirectly),
            ("testCurrentSnapshotEqualLayoutDirectly", testCurrentSnapshotEqualLayoutDirectly),
            ("testCoordinateSpacePointLayoutGuide", testCoordinateSpacePointLayoutGuide),
            ("testLayoutDistribution", testLayoutDistribution),
            ("testLayoutDistributionFunc1Performance", testLayoutDistributionFunc1Performance),
            ("testLayoutDistributionFunc2Performance", testLayoutDistributionFunc2Performance),
            ("testStackLayoutScheme", testStackLayoutScheme),
            ("testLayoutWorkspaceBeforeLeadingAlign", testLayoutWorkspaceBeforeLeadingAlign),
            ("testLayoutWorkspaceAfterLeadingAlign", testLayoutWorkspaceAfterLeadingAlign),
            ("testLayoutWorkspaceBeforeTrailingAlign", testLayoutWorkspaceBeforeTrailingAlign),
            ("testLayoutWorkspaceAfterTrailingAlign", testLayoutWorkspaceAfterTrailingAlign)
        ]

        #if os(iOS)
        tests += [
            ("testStackLayoutGuideSizeThatFits", testStackLayoutGuideSizeThatFits),
            ("testStackLayoutGuideAddRemoveLayoutItems", testStackLayoutGuideAddRemoveLayoutItems),
            ("testRemoveStackLayoutFromSuperItem", testRemoveStackLayoutFromSuperItem)
        ]
        #endif
        return tests
    }
}
