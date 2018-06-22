//
//  scroll.layoutGuide.cglayout.swift
//  CGLayout
//
//  Created by Denis Koryttsev on 21/06/2018.
//

import Foundation

/// Version - Pre Alpha

// MARK: ScrollLayoutGuide

/// Layout guide that provides interface for scrolling content
open class ScrollLayoutGuide<Super: LayoutItem>: LayoutGuide<Super> {
    private var layout: LayoutBlockProtocol

    /// Designed initializer
    ///
    /// - Parameter layout: Layout defined scrollable content
    public required init(layout: LayoutBlockProtocol) {
        self.layout = layout
        super.init(frame: .zero)
    }

    /// Point that defines offset for content origin
    open var contentOffset: CGPoint { set { bounds.origin = newValue } get { return bounds.origin } }
    /// Size of content
    open var contentSize: CGSize = .zero//{ set { bounds.size = contentSize } get { return bounds.size } } // TODO: Size of bounds should be equal frame size.
    open var contentInset: EdgeInsets = .zero {
        didSet {
            if oldValue != contentInset {
                let x = contentInset.left - oldValue.left
                let y = contentInset.top - oldValue.top

                contentOffset = CGPoint(x: contentOffset.x - x, y: contentOffset.y - y)
            }
        }
    }

    override public var layoutBounds: CGRect { return CGRect(origin: CGPoint(x: frame.origin.x - contentOffset.x, y: frame.origin.y - contentOffset.y), size: contentSize) }
    /// Performs layout for subitems, which this layout guide manages, in layout space rect
    ///
    /// - Parameter rect: Space for layout
    override open func layout(in rect: CGRect) {
        super.layout(in: rect)
        layout.layout(in: rect)
    }

    /// Defines rect for content that will be visible in this guide space.
    ///
    /// - Parameter frame: New frame value.
    /// - Returns: Content rect
    override open func contentRect(forFrame frame: CGRect) -> CGRect {
        //        var contentRect = bounds
        //        let lFrame = layoutBounds
        //        let snapshotFrame = CGRect(x: lFrame.origin.x, y: lFrame.origin.y, width: max(contentRect.width, frame.width), height: max(contentRect.height, frame.height))
        //        contentRect.size = layout.snapshot(for: snapshotFrame).snapshotFrame.distance(from: frame.origin)
        //        return contentRect
        var bounds = frame; bounds.origin = contentOffset
        return bounds
    }
}
public extension ScrollLayoutGuide {
    /// Convinience initializer for adjustable layout items.
    /// Initializes layout guide with layout block constrained to calculated size of item.
    ///
    /// - Parameters:
    ///   - contentItem: Item that defines content
    ///   - direction: Scroll direction
    public convenience init<Item: AdjustableLayoutItem>(contentItem: Item, direction: ScrollDirection) {
        self.init(layout: contentItem.layoutBlock(with: Layout.equal, constraints: [contentItem.adjustLayoutConstraint(for: direction.constraints)]))
    }
}
/// Defines limiters for content of scroll layout guide.
public struct ScrollDirection: OptionSet {
    public
    var rawValue: Int
    public
    init(rawValue: Int) {
        switch rawValue {
        case 1: self = .horizontal
        case 2: self = .vertical
        default:
            self = .both
        }
    }

    let constraints: [LayoutAnchor.Size]

    init(constraints: [LayoutAnchor.Size], rawValue: Int) {
        self.constraints = constraints
        self.rawValue = rawValue
    }

    public static var horizontal: ScrollDirection = ScrollDirection(constraints: [.width()], rawValue: 1)
    public static var vertical: ScrollDirection = ScrollDirection(constraints: [.height()], rawValue: 2)
    public static var both: ScrollDirection = ScrollDirection(constraints: [.height(), .width()], rawValue: 0)
}

func LinearInterpolation(t: CGFloat, start: CGFloat, end: CGFloat) -> CGFloat {
    if t <= 0 {
        return start
    }
    else if t >= 1 {
        return end
    }
    else {
        return t * end + (1 - t) * start
    }
}

func QuadraticEaseOut(t: CGFloat, start: CGFloat, end: CGFloat) -> CGFloat {
    if t <= 0 {
        return start
    }
    else if t >= 1 {
        return end
    }
    else {
        return LinearInterpolation(t: 2 * t - t * t, start: start, end: end)
    }
}

protocol ScrollAnimation {
    var beginTime: TimeInterval { get set }
    func animateX()
    func animateY()
}

struct ScrollAnimationDecelerationComponent {
    var decelerateTime: TimeInterval
    var position: CGFloat
    var velocity: CGFloat
    var returnTime: TimeInterval
    var returnFrom: CGFloat
    var bounced: Bool
    var bouncing: Bool
}

private let minimumBounceVelocityBeforeReturning: CGFloat = 100
private let returnAnimationDuration: TimeInterval = 0.33
private let physicsTimeStep: TimeInterval = 1 / 120.0
private let springTightness: CGFloat = 7
private let springDampening: CGFloat = 15

private func Clamp(v: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
    return (v < min) ? min : (v > max) ? max : v
}

private func ClampedVelocty(v: CGFloat) -> CGFloat {
    let V: CGFloat = 500
    return Clamp(v: v, min: -V, max: V)
}

private func Spring(velocity: CGFloat, position: CGFloat, restPosition: CGFloat, tightness: CGFloat, dampening: CGFloat) -> CGFloat {
    let d: CGFloat = position - restPosition
    return (-tightness * d) - (dampening * velocity)
}

private func BounceComponent(t: TimeInterval, c: inout ScrollAnimationDecelerationComponent, to: CGFloat) -> Bool {
    if c.bounced && c.returnTime != 0 {
        let returnBounceTime: TimeInterval = min(1, ((t - c.returnTime) / returnAnimationDuration))
        c.position = QuadraticEaseOut(t: CGFloat(returnBounceTime), start: c.returnFrom, end: to)
        return returnBounceTime == 1
    }
    else if abs(to - c.position) > 0 {
        let F: CGFloat = Spring(velocity: c.velocity, position: c.position, restPosition: to, tightness: springTightness, dampening: springDampening)
        c.velocity += F * CGFloat(physicsTimeStep)
        c.position += -c.velocity * CGFloat(physicsTimeStep)
        c.bounced = true
        if abs(c.velocity) < minimumBounceVelocityBeforeReturning {
            c.returnFrom = c.position
            c.returnTime = t
        }
        return false
    }
    else {
        return true
    }
}

extension ScrollLayoutGuide {
    func _confinedContentOffset(_ contentOffset: CGPoint) -> CGPoint {
        let scrollerBounds: CGRect = EdgeInsetsInsetRect(bounds, contentInset)
        var contentOffset = contentOffset
        if (contentSize.width - contentOffset.x) < scrollerBounds.size.width {
            contentOffset.x = contentSize.width - scrollerBounds.size.width
        }
        if (contentSize.height - contentOffset.y) < scrollerBounds.size.height {
            contentOffset.y = contentSize.height - scrollerBounds.size.height
        }
        contentOffset.x = max(contentOffset.x, 0)
        contentOffset.y = max(contentOffset.y, 0)
        if contentSize.width <= scrollerBounds.size.width {
            contentOffset.x = 0
        }
        if contentSize.height <= scrollerBounds.size.height {
            contentOffset.y = 0
        }
        return contentOffset
    }
    func _setRestrainedContentOffset(_ offset: CGPoint) {
        var offset = offset
        let confinedOffset: CGPoint = _confinedContentOffset(offset)
        let scrollerBounds: CGRect = EdgeInsetsInsetRect(bounds, contentInset)
        if !(/*alwaysBounceHorizontal && */contentSize.width <= scrollerBounds.size.width) {
            offset.x = confinedOffset.x
        }
        if !(/*alwaysBounceVertical && */contentSize.height <= scrollerBounds.size.height) {
            offset.y = confinedOffset.y
        }
        contentOffset = offset
    }
}

public class ScrollAnimationDeceleration<Item: LayoutItem>: ScrollAnimation {
    private var x: ScrollAnimationDecelerationComponent
    private var y: ScrollAnimationDecelerationComponent
    private var lastMomentumTime: TimeInterval
    private(set) weak var scrollGuide: ScrollLayoutGuide<Item>!
    var beginTime: TimeInterval = Date.timeIntervalSinceReferenceDate

    public init(scrollGuide sg: ScrollLayoutGuide<Item>, velocity v: CGPoint) {
        self.scrollGuide = sg

        startVelocity = v
        lastMomentumTime = beginTime
        x = ScrollAnimationDecelerationComponent(decelerateTime: beginTime,
                                                 position: scrollGuide.contentOffset.x,
                                                 velocity: startVelocity.x,
                                                 returnTime: 0,
                                                 returnFrom: 0,
                                                 bounced: false,
                                                 bouncing: false)
        y = ScrollAnimationDecelerationComponent(decelerateTime: beginTime,
                                                 position: scrollGuide.contentOffset.y,
                                                 velocity: startVelocity.y,
                                                 returnTime: 0,
                                                 returnFrom: 0,
                                                 bounced: false,
                                                 bouncing: false)
        if x.velocity == 0 {
            x.bounced = true
            x.returnTime = beginTime
            x.returnFrom = x.position
        }
        if y.velocity == 0 {
            y.bounced = true
            y.returnTime = beginTime
            y.returnFrom = y.position
        }
    }

    func animateY() {
        let currentTime: TimeInterval = Date.timeIntervalSinceReferenceDate
        y.bouncing = true
        while y.bouncing && currentTime >= beginTime {
            let confinedOffset = scrollGuide._confinedContentOffset(CGPoint(x: x.position, y: y.position))
            y.bouncing = !BounceComponent(t: beginTime, c: &y, to: confinedOffset.y)
            beginTime += physicsTimeStep
            scrollGuide.contentOffset.y = y.position//min(max(-scrollGuide.bounds.height, y.position), scrollGuide.layoutBounds.maxY - scrollGuide.bounds.height)
        }
    }

    func animateX() {
        let currentTime: TimeInterval = Date.timeIntervalSinceReferenceDate
        x.bouncing = true
        while x.bouncing && currentTime >= beginTime {
            let confinedOffset = scrollGuide._confinedContentOffset(CGPoint(x: x.position, y: y.position))
            x.bouncing = !BounceComponent(t: beginTime, c: &x, to: confinedOffset.x)
            beginTime += physicsTimeStep
            scrollGuide.contentOffset.x = min(max(-scrollGuide.bounds.width/2, x.position), scrollGuide.layoutBounds.maxX - scrollGuide.bounds.width/2)
        }
    }

    let timeInterval: CGFloat = 1/60
    let startVelocity: CGPoint
    var needBouncing = true

    public func step(_ timer: Timer) {
        func stopIfNeeded() {
            if abs(x.velocity) <= 0.001 && abs(y.velocity) <= 0.001 {
                timer.invalidate()
            }
        }

        guard let guide = scrollGuide, (abs(x.velocity) >= 0.001 && abs(y.velocity) >= 0.001) else {
            timer.invalidate()
            return
        }

        var offset = guide.contentOffset
        if needBouncing {
            if !x.bouncing {
                offset.x += -x.velocity * timeInterval
            }
            if !y.bouncing {
                offset.y += -y.velocity * timeInterval
            }

            guide.contentOffset = offset
            if (offset.x < 0 || offset.x > scrollGuide.contentSize.width - scrollGuide.frame.width) {
                x.position = offset.x
                animateX()
                stopIfNeeded()
            }
            if (offset.y < 0 || offset.y > scrollGuide.contentSize.height - scrollGuide.frame.height) {
                y.position = offset.y
                animateY()
                stopIfNeeded()
            }
        } else {
            offset.x += -x.velocity * timeInterval
            offset.y += -y.velocity * timeInterval
            guide._setRestrainedContentOffset(offset)
        }

        lastMomentumTime = Date.timeIntervalSinceReferenceDate
        let friction: CGFloat = 0.96
        let drag: CGFloat = pow(pow(friction, 60), CGFloat(lastMomentumTime - beginTime))
        if !x.bouncing {
            x.velocity = startVelocity.x * drag
        }
        if !y.bouncing {
            y.velocity = startVelocity.y * drag
        }
    }
}
