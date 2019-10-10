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


/// The container does not know which child is being added,
/// but the child knows exactly where it is being added

protocol EnterPointProtocol {
    associatedtype Container
    func add(to container: Container)
}

struct EnterPoint<Child, Container> {
    let child: Child
}

#if os(iOS)
extension EnterPoint: EnterPointProtocol where Child: UIView, Container: UIView {
    func add(to container: Container) {
        container.addSubview(child)
    }
}
//extension EnterPoint: EnterPointProtocol where Child: LayoutGuide<UIView>, Container: UIView { // conflict
//    func add(to container: Container) {
//        container.add(layoutGuide: child)
//    }
//}

extension StackLayoutGuide where Parent: UIView {
    var views: Views { return Views(stackLayoutGuide: self) }
    struct Views: ChildrenProtocol {
        let stackLayoutGuide: StackLayoutGuide<Parent>
        func add(_ child: UIView) {
            stackLayoutGuide.ownerElement?.addSubview(child)
            stackLayoutGuide.items.append(child)
        }
    }

    var layers: Layers { return Layers(stackLayoutGuide: self) }
    struct Layers: ChildrenProtocol {
        let stackLayoutGuide: StackLayoutGuide<Parent>
        func add(_ child: CALayer) {
            stackLayoutGuide.ownerElement?.layer.addSublayer(child)
            stackLayoutGuide.items.append(child)
        }
    }

    var layoutGuides: LayoutGuides { return LayoutGuides(stackLayoutGuide: self) }
    struct LayoutGuides: ChildrenProtocol {
        let stackLayoutGuide: StackLayoutGuide<Parent>
        func add(_ child: LayoutGuide<UIView>) {
            stackLayoutGuide.ownerElement?.add(layoutGuide: child)
            stackLayoutGuide.items.append(child)
        }
    }
}

protocol ChildrenProtocol {
    associatedtype Child
    func add(_ child: Child)
}
struct Children<Child, Container> {
    let container: Container
}
extension Children where Child: UIView, Container: UIView {
    func add(_ child: Child) {
        container.addSubview(child)
    }
}
extension Children where Child: CALayer, Container: UIView {
    func add(_ child: Child) {
        container.layer.addSublayer(child)
    }
}
extension UIView {
    var children: Children<UIView, UIView> { return Children(container: self) }
    var sublayers: Children<CALayer, UIView> { return Children(container: self) }
}

#endif
