//
//  LayoutItemContainer.swift
//  Pods
//
//  Created by Denis Koryttsev on 01/10/2017.
//
//

import Foundation

public protocol LayoutItemContainer: LayoutItem {
    var sublayoutItems: [LayoutItem]? { get }

    func addSublayoutItem<SubItem: LayoutItem>(_ subItem: SubItem)
    func removeSublayoutItem<SubItem: LayoutItem>(_ subItem: SubItem)
}

extension CALayer: LayoutItemContainer {
    public weak var superItem: LayoutItem? { return superlayer }
    public var sublayoutItems: [LayoutItem]? { return sublayers }

    public func addSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : LayoutItem {}
    public func removeSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : LayoutItem {}

    public func addSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : LayoutGuide<CALayer> {
        add(layoutGuide: subItem)
    }
    public func removeSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : LayoutGuide<CALayer> {
        subItem.removeFromOwner()
    }

    public func addSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : CALayer {
        addSublayer(subItem)
    }
    public func removeSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : CALayer {
        subItem.removeFromSuperlayer()
    }
}

extension UIView: LayoutItemContainer {
    public var sublayoutItems: [LayoutItem]? { return subviews }

    public func addSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : LayoutItem {}
    public func removeSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : LayoutItem {}

    public func addSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : LayoutGuide<UIView> {
        add(layoutGuide: subItem)
    }
    public func removeSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : LayoutGuide<UIView> {
        subItem.removeFromOwner()
    }

    @available(iOS 9.0, *)
    public func addSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : UILayoutGuide {
        addLayoutGuide(subItem)
    }
    @available(iOS 9.0, *)
    public func removeSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : UILayoutGuide {
        removeLayoutGuide(subItem)
    }
    public func addSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : CALayer {
        layer.addSublayer(subItem)
    }
    public func removeSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : CALayer {
        subItem.removeFromSuperlayer()
    }
    public func addSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : UIView {
        addSubview(subItem)
    }
    public func removeSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : UIView {
        subItem.removeFromSuperview()
    }
}
