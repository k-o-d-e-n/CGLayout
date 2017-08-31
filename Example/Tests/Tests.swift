import UIKit
import XCTest
@testable import CGLayout_Example
@testable import CGLayout

class Tests: XCTestCase {
    
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

extension CGRect {
    static func random(in source: CGRect) -> CGRect {
        let o = CGPoint(x: CGFloat(arc4random_uniform(UInt32(source.width))), y: CGFloat(arc4random_uniform(UInt32(source.height))))
        let s = CGSize(width: CGFloat(arc4random_uniform(UInt32(source.width - o.x))), height: CGFloat(arc4random_uniform(UInt32(source.height - o.y))))

        return CGRect(origin: o, size: s)
    }
}
