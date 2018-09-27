//
//  LayoutElementsContainer.swift
//  CGLayout
//
//  Created by Denis Koryttsev on 01/10/2017.
//
//

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import Cocoa
#elseif os(Linux)
import Foundation
#endif

public protocol LayoutElementsContainer: LayoutElement {
    func addChildElement<SubItem: LayoutElement>(_ subItem: SubItem)

    func addChild<Point: EnterPoint>(using point: Point) where Point.Container == Self
}
extension LayoutElementsContainer {
    public func addChild<Point: EnterPoint>(using point: Point) where Point.Container == Self {
        point.add(to: self)
    }
    public func addChild(using point: Enter<Self>) {
        point.add(to: self)
    }
}

#if os(macOS) || os(iOS) || os(tvOS)
extension CALayer: LayoutElementsContainer {
    public func addChildElement<SubItem>(_ subItem: SubItem) where SubItem : LayoutElement {
        debugFatalError(true, "\(self) cannot add subitem \(subItem). Reason: Undefined type of subitem")

        // TODO: Implement addition subitem with type cast
    }

    public func addChildElement<SubItem>(_ subItem: SubItem) where SubItem : LayoutGuide<CALayer> {
        add(layoutGuide: subItem)
    }
    public func addChildElement<SubItem>(_ subItem: SubItem) where SubItem : CALayer {
        addSublayer(subItem)
    }
}
#endif
#if os(iOS) || os(tvOS)
extension CALayer {
    public func addChildElement<SubItem>(_ subItem: SubItem) where SubItem : UIView {
        addSublayer(subItem.layer)
        debugWarning("Adds 'UIView' element to 'CALayer' element directly has ambiguous behavior")
    }
}

extension UIView: LayoutElementsContainer {
    public func addChildElement<SubItem>(_ subItem: SubItem) where SubItem : LayoutElement {
        debugFatalError(true, "\(self) cannot add subitem \(subItem). Reason: Undefined type of subitem")

        // TODO: Implement addition subitem with type cast
    }

    public func addChildElement<SubItem>(_ subItem: SubItem) where SubItem : LayoutGuide<CALayer> {
        layer.add(layoutGuide: subItem)
    }
    public func addChildElement<SubItem>(_ subItem: SubItem) where SubItem : LayoutGuide<UIView> {
        add(layoutGuide: subItem)
    }
    @available(iOS 9.0, *)
    public func addChildElement<SubItem>(_ subItem: SubItem) where SubItem : UILayoutGuide {
        addLayoutGuide(subItem)
    }
    public func addChildElement<SubItem>(_ subItem: SubItem) where SubItem : CALayer {
        layer.addSublayer(subItem)
    }
    public func addChildElement<SubItem>(_ subItem: SubItem) where SubItem : UIView {
        addSubview(subItem)
    }
}
#endif

#if os(macOS)
extension NSView: LayoutElementsContainer {
    public func addChildElement<SubItem>(_ subItem: SubItem) where SubItem : LayoutElement {
        debugFatalError(true, "\(self) cannot add subitem \(subItem). Reason: Undefined type of subitem")

        // TODO: Implement addition subitem with type cast
    }

    public func addChildElement<SubItem>(_ subItem: SubItem) where SubItem : LayoutGuide<CALayer> {
        layer?.add(layoutGuide: subItem)
    }
    public func addChildElement<SubItem>(_ subItem: SubItem) where SubItem : LayoutGuide<NSView> {
        add(layoutGuide: subItem)
    }
    @available(macOS 10.11, *)
    public func addChildElement<SubItem>(_ subItem: SubItem) where SubItem : NSLayoutGuide {
        addLayoutGuide(subItem)
    }
    public func addChildElement<SubItem>(_ subItem: SubItem) where SubItem : CALayer {
        layer?.addSublayer(subItem)
    }
    public func addChildElement<SubItem>(_ subItem: SubItem) where SubItem : NSView {
        addSubview(subItem)
    }
}
#endif

public protocol EnterPoint {
    associatedtype Container

    var child: LayoutElement { get }

    func add(to container: Container)
}

public struct Enter<Container>: EnterPoint {
    let _element: LayoutElement
    let _enter: (Container) -> Void
    public var child: LayoutElement { return _element }

    public init<Point: EnterPoint>(_ base: Point) where Point.Container == Container {
        self._element = base.child
        self._enter = base.add
    }

    public init<Child: LayoutElement>(_ element: Child, _ enter: @escaping (Child, Container) -> Void) {
        self._element = element
        self._enter = { enter(element, $0) }
    }

    public func add(to container: Container) {
        _enter(container)
    }
}

struct _Enter<Child: LayoutElement, Container>: EnterPoint {
    let _element: Child
    let _enter: (Child, Container) -> Void

    var child: LayoutElement { return _element }

    init(_ element: Child, _ enter: @escaping (Child, Container) -> Void) {
        self._element = element
        self._enter = enter
    }

    func add(to container: Container) {
        _enter(_element, container)
    }
}

#if os(iOS) || os(tvOS)

extension _Enter where Child: UIView, Container: UIView {
    init(_ child: Child) {
        self.init(child) { (subview, view) in
            view.addSubview(subview)
        }
    }
}
extension _Enter where Child: CALayer, Container: UIView {
    init(_ child: Child) {
        self.init(child) { sublayer, view in
            view.layer.addSublayer(sublayer)
        }
    }
}
extension _Enter where Child: CALayer, Container: CALayer {
    init(_ child: Child) {
        self.init(child) { (sublayer, layer) in
            layer.addSublayer(sublayer)
        }
    }
}
extension _Enter where Container: UIView {
    init<Super: UIView>(_ child: Child) where Child: LayoutGuide<Super> {
        self.init(child) { lg, view in
            view.add(layoutGuide: lg)
        }
    }
    init<Super: CALayer>(_ child: Child) where Child: LayoutGuide<Super> {
        self.init(child) { lg, view in
            view.layer.add(layoutGuide: lg)
        }
    }
}

#endif
