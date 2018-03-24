import XCTest
@testable import CGLayout

struct View {
	var frame: CGRect
}

class CGLayoutTests: XCTestCase {
    let bounds = CGRect(x: 0, y: 0, width: 500, height: 500)
	func testTopAlignment() {
        var view1 = View(frame: CGRect(x: 230, y: 305, width: 200, height: 100))
        let view2 = View(frame: bounds)
        let alignment = Layout.Alignment.Vertical.top()

        alignment.formLayout(rect: &view1.frame, in: view2.frame)

        XCTAssertTrue(view1.frame.minY == view2.frame.minY)
    }


    static var allTests = [
        ("testTopAlignment", testTopAlignment),
    ]
}
