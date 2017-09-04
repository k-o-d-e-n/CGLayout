//
//  CGLayoutExtended.swift
//  Pods
//
//  Created by Denis Koryttsev on 04/09/2017.
//
//

import Foundation

/// LayoutGuides will not show up in the view hierarchy, but may be used as layout item in
/// an `RectBasedConstraint` and represent a rectangle in the layout engine.
/// Create a LayoutGuide with -init
/// Add to a view with UIView.add(layoutGuide:) if will be used him as item in RectBasedLayout.apply(for item:, use constraints:)
public class LayoutGuide: LayoutItem {
    public var frame: CGRect
    public var bounds: CGRect
    public var superItem: LayoutItem?

    public init(frame: CGRect) {
        self.frame = frame
        self.bounds = CGRect(origin: .zero, size: frame.size)
    }
}
public extension UIView {
    func add(layoutGuide: LayoutGuide) {
        layoutGuide.superItem = self
    }
}

// TODO: Create constraint for attributed string

/// Size-based constraint for constrain source rect by size of string. The size to draw gets from restrictive rect.
public struct StringLayoutConstraint: ConstraintItemProtocol {
    let string: String?
    let attributes: [String: Any]?
    let options: NSStringDrawingOptions
    let context: NSStringDrawingContext?

    public init(string: String?, options: NSStringDrawingOptions = .usesLineFragmentOrigin, attributes: [String: Any]? = nil, context: NSStringDrawingContext? = nil) {
        self.string = string
        self.attributes = attributes
        self.context = context
        self.options = options
    }

    public func constrain(sourceRect: inout CGRect, by rect: CGRect) {
        sourceRect.size = string?.boundingRect(with: rect.size, options: options, attributes: attributes, context: context).size ?? .zero
    }

    public func constrainRect(for currentSpace: CGRect) -> CGRect {
        return currentSpace
    }
}
extension String {
    func layoutConstraint(with attributes: [String: Any]? = nil, context: NSStringDrawingContext? = nil) -> StringLayoutConstraint {
        return StringLayoutConstraint(string: self, attributes: attributes, context: context)
    }
}
