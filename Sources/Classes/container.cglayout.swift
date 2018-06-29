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
