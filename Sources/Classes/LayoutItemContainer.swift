//
//  LayoutItemContainer.swift
//  CGLayout
//
//  Created by Denis Koryttsev on 01/10/2017.
//
//

import Foundation

// TODO: !! Add layout call to layout item, for invoke relayout when adjusted view changed size and other cases.
//public protocol LayoutItemContainer {
//    func setNeedsLayout()
//}

public protocol LayoutItemContainer: LayoutItem {
    func addSublayoutItem<SubItem: LayoutItem>(_ subItem: SubItem)
}

#if os(macOS) || os(iOS) || os(tvOS)
extension CALayer: LayoutItemContainer {
    public func addSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : LayoutItem {}

    public func addSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : LayoutGuide<CALayer> {
        add(layoutGuide: subItem)
    }
    public func addSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : CALayer {
        addSublayer(subItem)
    }
    public func addSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : UIView {
        addSublayer(subItem.layer)
        debugWarning("Adds 'UIView' element to 'CALayer' element directly has ambiguous behavior")
    }
}
#endif

#if os(iOS) || os(tvOS)
extension UIView: LayoutItemContainer {
    public func addSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : LayoutItem {}

    public func addSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : LayoutGuide<CALayer> {
        layer.add(layoutGuide: subItem)
    }
    public func addSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : LayoutGuide<UIView> {
        add(layoutGuide: subItem)
    }
    @available(iOS 9.0, *)
    public func addSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : UILayoutGuide {
        addLayoutGuide(subItem)
    }
    public func addSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : CALayer {
        layer.addSublayer(subItem)
    }
    public func addSublayoutItem<SubItem>(_ subItem: SubItem) where SubItem : UIView {
        addSubview(subItem)
    }
}
#endif
