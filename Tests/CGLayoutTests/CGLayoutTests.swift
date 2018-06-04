import XCTest
@testable import CGLayout

class CGLayoutTests: XCTestCase {
    let bounds = CGRect(x: 0, y: 0, width: 500, height: 500)
	func testTopAlignment() {
        let view1 = Layer(frame: CGRect(x: 230, y: 305, width: 200, height: 100))
        let view2 = Layer(frame: bounds)
        let alignment = Layout.Alignment.Vertical.top()

        alignment.formLayout(rect: &view1.frame, in: view2.frame)

        XCTAssertTrue(view1.frame.origin.y == view2.frame.origin.y)
    }

    func testContainer() {
        let layer = Layer(frame: CGRect(x: 230, y: 305, width: 200, height: 100))
        let view = View(layer: layer)
        let lg = LayoutGuide<View>(frame: .zero)
        let subview = View(frame: CGRect(x: 230, y: 305, width: 200, height: 100))

        view.addSubItem(.layoutGuide(.inView(lg)))
        view.addSubItem(.view(subview))

        XCTAssertTrue(lg.ownerItem! === view)
        XCTAssertTrue(view.subviews.contains(where: { $0 === subview }))
        XCTAssertTrue(view.layer.sublayers.contains(where: { $0 === subview.layer }))
    }

    func testContainer2() {
        let layer = Layer(frame: CGRect(x: 230, y: 305, width: 200, height: 100))
        let view = View(layer: layer)
        let lg = LayoutGuide<View>(frame: .zero)
        let subview = View(frame: CGRect(x: 230, y: 305, width: 200, height: 100))

        view.addChild(from: lg)
        // view.addChild(from: AnyEnter<LayoutGuide<View>, View>(child: lg))
        view.addChild(from: AnyEnter<View, View>(child: subview))
        // view.addChild(from: LayoutGuideEnterPoint(lg))
        // view.addChild(from: ViewEnterPoint(subview))
        // view.addChild(lg)
        // view.addChild(subview)
        // lg.add(to: view)
        // subview.add(to: view)

        XCTAssertTrue(lg.ownerItem! === view)
        XCTAssertTrue(view.subviews.contains(where: { $0 === subview }))
        XCTAssertTrue(view.layer.sublayers.contains(where: { $0 === subview.layer }))
    }

    func testContainer3() {
        let window = Window(frame: CGRect(x: 230, y: 305, width: 200, height: 100))
        let view = View(frame: .zero)

        window.addChild(from: AnyEnter<View, Window>(child: view))
        // view.add(to: window)

        XCTAssertTrue(window.subviews.contains(where: { $0 === view }))
        XCTAssertTrue(window.layer.sublayers.contains(where: { $0 === view.layer }))
    }

    func testTextPresented() {
        let window = Window(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        let view = View(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
        let label = Label(frame: CGRect(x: 0, y: 100, width: 200, height: 50))
        window.addSubview(view)
        window.addSubview(label)

        let viewLayout = view.layoutBlock(constraints: [label.baselineLayoutConstraint(for: [LayoutAnchor.Bottom.align(by: .inner)])])

        viewLayout.layout()

        // print(view.frame)
        XCTAssertTrue(view.frame.maxY == 100 + label.baselinePosition)
    }

    func testTextPresented2() {
        let window = Window(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        let label1 = Label(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
        let label2 = Label(frame: CGRect(x: 0, y: 100, width: 200, height: 50))
        label1.baselinePosition = 35.0
        window.addSubview(label1)
        window.addSubview(label2)

        let label1Layout = label1.layoutBlock(constraints: [label2.baselineLayoutConstraint(for: [LayoutAnchor.Baseline.align(of: label1)])])

        label1Layout.layout()

        // print(label1.frame)
        XCTAssertTrue(label1.frame.minY == 100 + label2.baselinePosition - label1.baselinePosition)
    }

    func testNewAnchors() {
        let window = Window(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        let sourceView = View(frame: CGRect(x: 100, y: 100, width: 300, height: 300))
        let targetView = View(frame: .zero)
        window.addSubview(sourceView)
        sourceView.addSubview(targetView)
        let layout = targetView.layout { (anchors) in
            anchors.size.equal(to: CGSize(width: 200, height: 40))
            anchors.center.align(by: sourceView.anchors.center)
            // anchors.top.align(by: sourceView.anchors.bottom)
            // anchors.origin.align(by: associatedView.anchors.origin)
            // anchors.top.align(by: window.anchors.top)
            // anchors.bottom.pull(to: sourceView.anchors.bottom)
        }

        // print("Before: ", targetView.frame)
        layout.layout()
        // print("After: ", targetView.frame)

        XCTAssertTrue(targetView.frame.origin.x == ((500 - 200) - 200) / 2)
        XCTAssertTrue(targetView.frame.origin.y == ((500 - 200) - 40) / 2)
        XCTAssertTrue(targetView.frame.size.width == 200)
        XCTAssertTrue(targetView.frame.size.height == 40)
    }

    func testNewAnchors2() {
        let window = Window(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        let sourceView = View(frame: CGRect(x: 100, y: 100, width: 300, height: 300))
        let targetView = View(frame: .zero)
        window.addSubview(sourceView)
        sourceView.addSubview(targetView)
        let layout = targetView.block { (anchors) in
            anchors.width.equal(to: 200)
            anchors.height.equal(to: 40)
            anchors.centerX.align(by: sourceView.layoutAnchors.centerX)
            anchors.centerY.align(by: sourceView.layoutAnchors.centerY)
        }

        // print("Before: ", targetView.frame)
        layout.layout()
        // print("After: ", targetView.frame)

        XCTAssertTrue(targetView.frame.origin.x == ((500 - 200) - 200) / 2)
        XCTAssertTrue(targetView.frame.origin.y == ((500 - 200) - 40) / 2)
        XCTAssertTrue(targetView.frame.size.width == 200)
        XCTAssertTrue(targetView.frame.size.height == 40)
    }

    func testNewAnchors3() {
        let window = Window(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        let sourceView = View(frame: CGRect(x: 100, y: 100, width: 300, height: 300))
        let targetView = View(frame: .zero) 
        window.addSubview(sourceView)
        sourceView.addSubview(targetView)
        let layout = targetView.block { (anchors) in
            // anchors.centerY.align(by: sourceView.layoutAnchors.centerY) // 4
            anchors.height.scaled(by: sourceView.layoutAnchors.height, scale: 0.5) // 3
            anchors.left.pull(to: sourceView.layoutAnchors.centerX) // 1
            anchors.right.pull(to: sourceView.layoutAnchors.right) // 5, conflicted and broken down #2
            // anchors.width.equal(to: 300) // 2
            // anchors.top.limit(by: sourceView.layoutAnchors.centerY) // 6, conflicted and broken down #3, #4
            // anchors.top.align(by: sourceView.layoutAnchors.centerY)
            anchors.top.fartherThanOrEqual(to: sourceView.layoutAnchors.centerY)

            // print(anchors.constraints.reduce(CGRect.zero, { current, constraints in
            //     print(current)
            //     return current.constrainedBy(rect: sourceView.bounds, use: constraints)
            // }))
        }

        // print("Before: ", targetView.frame)
        layout.layout()
        // print("After: ", targetView.frame)

        XCTAssertTrue(targetView.frame.origin.x == 150)
        XCTAssertTrue(targetView.frame.origin.y == 150)
        XCTAssertTrue(targetView.frame.size.width == 150)
        XCTAssertTrue(targetView.frame.size.height == 150)
    }

    func testNewAnchors4() {
        let window = Window(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        let sourceView = View(frame: CGRect(x: 100, y: 100, width: 300, height: 300))
        let targetView = Label(frame: .zero)
        targetView.text = "Test label intrinsic size"
        window.addSubview(sourceView)
        sourceView.addSubview(targetView)

        let layout = targetView.block { (anchors) in
            // anchors.centerY.align(by: sourceView.layoutAnchors.centerY) // 4
            anchors.height.equalIntrinsicSize() // 3
            anchors.left.pull(to: sourceView.layoutAnchors.centerX) // 1
            anchors.right.pull(to: sourceView.layoutAnchors.right) // 5, conflicted and broken down #2
            // anchors.width.equalIntrinsicSize() // 2
            // anchors.top.limit(by: sourceView.layoutAnchors.centerY) // 6, conflicted and broken down #3, #4
            anchors.top.align(by: sourceView.layoutAnchors.centerY)

            // print(anchors.constraints.reduce(CGRect.zero, { current, constraints in
            //     print(current)
            //     return current.constrainedBy(rect: sourceView.bounds, use: constraints)
            // }))
        }

        // print("Before: ", targetView.frame)
        layout.layout()
        // print("After: ", targetView.frame)

        XCTAssertTrue(targetView.frame.origin.x == 150)
        XCTAssertTrue(targetView.frame.origin.y == 150)
        XCTAssertTrue(targetView.frame.size.width == 150)
        let height = targetView.contentConstraint.constrained(sourceRect: .zero, by: CGRect(x: 0, y: 0, width: 150, height: 0)).size.height
        XCTAssertTrue(targetView.frame.size.height == height)
    }

    static var allTests = [
        ("testTopAlignment", testTopAlignment),
        ("testContainer", testContainer),
        ("testContainer2", testContainer2),
        ("testContainer3", testContainer3),
        ("testTextPresented", testTextPresented),
        ("testTextPresented2", testTextPresented2),
        ("testNewAnchors", testNewAnchors),
        ("testNewAnchors2", testNewAnchors2),
        ("testNewAnchors3", testNewAnchors3),
        ("testNewAnchors4", testNewAnchors4)
    ]
}
