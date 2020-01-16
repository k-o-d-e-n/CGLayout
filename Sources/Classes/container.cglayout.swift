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

protocol EnterPoint {
    associatedtype Container

    var child: LayoutElement { get }

    func add(to container: Container)
}

protocol ContainerManagement {
    associatedtype Child
    associatedtype Container
    func add(_ child: Child, to container: Container)
}

struct Enter<Container>: EnterPoint {
    let base: _AnyEnterPoint<Container>
    var child: LayoutElement { return base.child }

    init<Point: EnterPoint>(_ base: Point) where Point.Container == Container {
        self.base = _Enter(base)
    }

    init<Management: ContainerManagement>(_ element: Management.Child, managedBy management: Management) where Management.Child: LayoutElement, Management.Container == Container {
        self.base = _Enter(Enter.Any.init(element: element, management: management))
    }

    func add(to container: Container) {
        base.add(to: container)
    }

    private struct `Any`<Management: ContainerManagement>: EnterPoint where Management.Child: LayoutElement, Management.Container == Container {
        let element: Management.Child
        let management: Management
        var child: LayoutElement { element }
        func add(to container: Container) {
            management.add(element, to: container)
        }
    }
}

class _AnyEnterPoint<Container>: EnterPoint {
    var child: LayoutElement { fatalError("Unimplemented") }
    func add(to container: Container) {
        fatalError("Unimplemented")
    }
}
final class _Enter<Base: EnterPoint>: _AnyEnterPoint<Base.Container> {
    private let base: Base
    override var child: LayoutElement { base.child }
    init(_ base: Base) {
        self.base = base
    }
    override func add(to container: Base.Container) {
        base.add(to: container)
    }
}


/// The container does not know which child is being added,
/// but the child knows exactly where it is being added

protocol ChildrenProtocol {
    associatedtype Child
    func add(_ child: Child)
  //func remove(_ child: Child)
}

#if os(iOS)
extension UIView {
    struct SublayerManagement<Container: UIView>: ContainerManagement {
        func add(_ child: CALayer, to container: Container) {
            container.layer.addSublayer(child)
        }
    }
}

extension CALayer {
    struct Layers: ChildrenProtocol {
        let layer: CALayer
        func add(_ child: CALayer) {
            layer.addSublayer(layer)
        }
    }
}

public extension UIView {
    var sublayers: Layers { return Layers(base: CALayer.Layers(layer: layer)) }
    struct Layers: ChildrenProtocol {
        let base: CALayer.Layers
        func add(_ child: CALayer) {
            base.add(child)
        }
    }
    var layoutGuides: LayoutGuides { return LayoutGuides(view: self) }
    struct LayoutGuides: ChildrenProtocol {
        let view: UIView
        func add(_ child: LayoutGuide<UIView>) {
            child.add(to: view)
        }
    }
}

public extension StackLayoutGuide where Parent: UIView {
    var views: Views { return Views(stackLayoutGuide: self) }
    struct Views: ChildrenProtocol {
        let stackLayoutGuide: StackLayoutGuide<Parent>
        func add(_ child: UIView) {
            stackLayoutGuide.ownerElement?.addSubview(child)
            stackLayoutGuide.items.append(.uiView(child))
        }
    }

    var layers: Layers { return Layers(stackLayoutGuide: self) }
    struct Layers: ChildrenProtocol {
        let stackLayoutGuide: StackLayoutGuide<Parent>
        func add(_ child: CALayer) {
            stackLayoutGuide.ownerElement?.layer.addSublayer(child)
            stackLayoutGuide.items.append(.caLayer(child))
        }
    }

    var layoutGuides: LayoutGuides { return LayoutGuides(stackLayoutGuide: self) }
    struct LayoutGuides: ChildrenProtocol {
        let stackLayoutGuide: StackLayoutGuide<Parent>
        func add(_ child: LayoutGuide<UIView>) {
            stackLayoutGuide.ownerElement?.add(layoutGuide: child)
            stackLayoutGuide.items.append(.layoutGuide(child))
        }
    }
}
#endif
