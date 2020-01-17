//
//  Layout.swift
//  CGLayout
//
//  Created by Denis Koryttsev on 29/08/2017.
//  Copyright © 2017 K-o-D-e-N. All rights reserved.
//

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import Cocoa
#elseif os(Linux)
import Foundation
#endif

// MARK: LayoutConstraint

/// Provides rect for constrain source space. Used for related constraints.
public protocol LayoutConstraintProtocol: RectBasedConstraint {
    /// Element identifier
    var elementIdentifier: ObjectIdentifier? { get }
    /// Flag, defines that constraint may be used for layout
    var isActive: Bool { get }

    /// Main function for constrain source space by other rect
    ///
    /// - Parameters:
    ///   - sourceRect: Source space
    ///   - rect: Rect for constrain
    func formConstrain(sourceRect: inout CGRect, by rect: CGRect?, in coordinateSpace: LayoutElement)
}
public extension LayoutConstraintProtocol {
    /// Returns constraint with possibility to change active state
    ///
    /// - Parameter active: Initial active state
    /// - Returns: Mutable layout constraint
    func active(_ active: Bool) -> MutableLayoutConstraint {
        return .init(base: self, isActive: active)
    }
}

/// Simple related constraint. Contains anchor constraints and layout element as source of frame for constrain
public struct LayoutConstraint {
    fileprivate let constraints: [RectBasedConstraint]
    private(set) weak var item: LayoutElement?
    internal var inLayoutTime: ElementInLayoutTime?
    internal var inLayoutTimeItem: ElementInLayoutTime? {
        return inLayoutTime ?? item?.inLayoutTime
    }

    public init(element: LayoutElement, constraints: [RectBasedConstraint]) {
        self.item = element
        self.inLayoutTime = element.inLayoutTime
        self.constraints = constraints
    }
}
extension LayoutConstraint: LayoutConstraintProtocol {
    public var elementIdentifier: ObjectIdentifier? { return item.map(ObjectIdentifier.init) }
    /// Flag, defines that constraint may be used for layout
    public var isActive: Bool { return inLayoutTimeItem?.superElement != nil }

    public /// Main function for constrain source space by other rect
    ///
    /// - Parameters:
    ///   - sourceRect: Source space
    ///   - rect: Rect for constrain
    func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
        constraints.forEach { (constraint) in
            constraint.formConstrain(sourceRect: &sourceRect, by: rect)
        }
    }

    public /// Converts rect from constraint coordinate space to destination coordinate space if needed.
    ///
    /// - Parameters:
    ///   - rect: Initial rect
    ///   - coordinateSpace: Destination coordinate space
    /// - Returns: Converted rect
    func convert(rectIfNeeded rect: CGRect, to coordinateSpace: LayoutElement) -> CGRect {
        guard let superLayoutItem = inLayoutTimeItem?.superElement else { fatalError("Constraint has not access to layout element or him super element. /n\(self)") }

        return coordinateSpace === superLayoutItem ? rect : coordinateSpace.convert(rect: rect, from: superLayoutItem)
    }

    public func formConstrain(sourceRect: inout CGRect, by rect: CGRect?, in coordinateSpace: LayoutElement) {
        guard let item = inLayoutTimeItem else { fatalError("Constraint has not access to layout item or him super item. /n\(self)") }
        formConstrain(sourceRect: &sourceRect, by: convert(rectIfNeeded: rect ?? item.frame, to: coordinateSpace))
    }
}

/// Related constraint for adjust size of source space. Contains size constraints and layout element for calculate size.
public struct AdjustLayoutConstraint {
    let anchors: [Size]
    let alignment: Layout.Alignment
    private(set) weak var item: AdjustableLayoutElement?

    public init(element: AdjustableLayoutElement, anchors: [Size], alignment: Layout.Alignment) {
        self.item = element
        self.anchors = anchors
        self.alignment = alignment
    }
}
extension AdjustLayoutConstraint: LayoutConstraintProtocol {
    public var elementIdentifier: ObjectIdentifier? { return nil }
    public /// Flag, defines that constraint may be used for layout
    var isActive: Bool { return item?.inLayoutTime.superElement != nil }

    public /// Main function for constrain source space by other rect
    ///
    /// - Parameters:
    ///   - sourceRect: Source space
    ///   - rect: Rect for constrain
    func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
        guard let item = item else { fatalError("Constraint has not access to layout element or him super element. /n\(self)") }

        let adjustedRect = item.contentConstraint.constrained(sourceRect: rect, by: rect)
        anchors.forEach { (constraint) in
            constraint.formConstrain(sourceRect: &sourceRect, by: adjustedRect)
        }
        alignment.formLayout(rect: &sourceRect, in: rect)
    }

    public func formConstrain(sourceRect: inout CGRect, by rect: CGRect?, in coordinateSpace: LayoutElement) {
        formConstrain(sourceRect: &sourceRect, by: rect ?? sourceRect)
    }
}

/// Related constraint that uses internal bounds to constrain, defined in 'layoutBounds' property
public struct ContentLayoutConstraint {
    fileprivate let constraints: [RectBasedConstraint]
    private(set) weak var item: LayoutElement?
    internal var inLayoutTime: ElementInLayoutTime?
    internal var inLayoutTimeItem: ElementInLayoutTime? {
        return inLayoutTime ?? item?.inLayoutTime
    }

    public init(element: LayoutElement, constraints: [RectBasedConstraint]) {
        self.item = element
        self.inLayoutTime = element.inLayoutTime
        self.constraints = constraints
    }
}
extension ContentLayoutConstraint: LayoutConstraintProtocol {
    public var elementIdentifier: ObjectIdentifier? { return item.map(ObjectIdentifier.init) }
    /// Flag, defines that constraint may be used for layout
    public var isActive: Bool { return inLayoutTimeItem?.superElement != nil }

    public /// Main function for constrain source space by other rect
    ///
    /// - Parameters:
    ///   - sourceRect: Source space
    ///   - rect: Rect for constrain
    func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
        constraints.forEach { (constraint) in
            constraint.formConstrain(sourceRect: &sourceRect, by: rect)
        }
    }

    public /// Converts rect from constraint coordinate space to destination coordinate space if needed.
    ///
    /// - Parameters:
    ///   - rect: Initial rect
    ///   - coordinateSpace: Destination coordinate space
    /// - Returns: Converted rect
    func convert(rectIfNeeded rect: CGRect, to coordinateSpace: LayoutElement) -> CGRect {
        guard let item = self.item else { fatalError("Constraint has not access to layout element or him super element. /n\(self)") }

        return coordinateSpace === item ? rect : coordinateSpace.convert(rect: rect, from: item)
    }

    public func formConstrain(sourceRect: inout CGRect, by rect: CGRect?, in coordinateSpace: LayoutElement) {
        guard let layoutItem = inLayoutTimeItem else { fatalError("Constraint has not access to layout element or him super element. /n\(self)") }
        formConstrain(sourceRect: &sourceRect, by: convert(rectIfNeeded: rect ?? layoutItem.layoutBounds, to: coordinateSpace))
    }
}

/// Layout constraint that creates possibility to change active state.
public class MutableLayoutConstraint: LayoutConstraintProtocol {
    private var base: LayoutConstraintProtocol
    private var _active = true

    /// Flag, defines that constraint may be used for layout
    public var isActive: Bool {
        set { _active = newValue }
        get { return _active && base.isActive }
    }
    public var elementIdentifier: ObjectIdentifier? { return base.elementIdentifier }

    /// Designed initializer
    ///
    /// - Parameters:
    ///   - base: Constraint for mutating
    ///   - isActive: Initial state
    public init(base: LayoutConstraintProtocol, isActive: Bool) {
        self.base = base
        self._active = isActive
    }

    public /// Main function for constrain source space by other rect
    ///
    /// - Parameters:
    ///   - sourceRect: Source space
    ///   - rect: Rect for constrain
    func formConstrain(sourceRect: inout CGRect, by rect: CGRect) { base.formConstrain(sourceRect: &sourceRect, by: rect) }
    public func formConstrain(sourceRect: inout CGRect, by rect: CGRect?, in coordinateSpace: LayoutElement) {
        base.formConstrain(sourceRect: &sourceRect, by: rect, in: coordinateSpace)
    }
}

// MARK: Additional constraints

/// Layout constraint for independent changing source space. Use him with anchors that not describes rect side (for example `LayoutAnchor.insets` or `LayoutAnchor.Size`).
public struct AnonymConstraint: LayoutConstraintProtocol {
    let anchors: [RectBasedConstraint]
    let constrainRect: ((CGRect) -> CGRect)?

    public init(anchors: [RectBasedConstraint], constrainRect: ((CGRect) -> CGRect)? = nil) {
        self.anchors = anchors
        self.constrainRect = constrainRect
    }

    public var elementIdentifier: ObjectIdentifier? { return nil }
    public /// Flag, defines that constraint may be used for layout
    var isActive: Bool { return true }

    /// Main function for constrain source space by other rect
    ///
    /// - Parameters:
    ///   - sourceRect: Source space
    ///   - rect: Rect for constrain
    public func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
        anchors.forEach { (constraint) in
            constraint.formConstrain(sourceRect: &sourceRect, by: rect)
        }
    }
    public func formConstrain(sourceRect: inout CGRect, by rect: CGRect?, in coordinateSpace: LayoutElement) {
        formConstrain(sourceRect: &sourceRect, by: constrainRect?(rect ?? sourceRect) ?? sourceRect)
    }
}
public extension AnonymConstraint {
    init(transform: @escaping (inout CGRect) -> Void) {
        self.init(anchors: [Equal()]) {
            var source = $0
            transform(&source)
            return source
        }
    }
}

// TODO: Create constraint for attributed string and other data oriented constraints

#if os(macOS) || os(iOS) || os(tvOS)
public extension String {
    #if os(macOS)
    typealias DrawingOptions = NSString.DrawingOptions
    #elseif os(iOS) || os(tvOS)
    typealias DrawingOptions = NSStringDrawingOptions
    #endif
}
@available(OSX 10.11, *) /// Size-based constraint for constrain source rect by size of string. The size to draw gets from restrictive rect.
public struct StringLayoutAnchor: RectBasedConstraint {
    let string: String?
    let attributes: [NSAttributedString.Key: Any]?
    let options: String.DrawingOptions
    let context: NSStringDrawingContext?

    /// Designed initializer
    ///
    /// - Parameters:
    ///   - string: String for size calculation
    ///   - options: String drawing options.
    ///   - attributes: A dictionary of text attributes to be applied to the string. These are the same attributes that can be applied to an NSAttributedString object, but in the case of NSString objects, the attributes apply to the entire string, rather than ranges within the string.
    ///   - context: The string drawing context to use for the receiver, specifying minimum scale factor and tracking adjustments.
    public init(string: String?, options: String.DrawingOptions = .usesLineFragmentOrigin, attributes: [NSAttributedString.Key: Any]? = nil, context: NSStringDrawingContext? = nil) {
        self.string = string
        self.attributes = attributes
        self.context = context
        self.options = options
    }

    public /// Main function for constrain source space by other rect
    ///
    /// - Parameters:
    ///   - sourceRect: Source space
    ///   - rect: Rect for constrain
    func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
        sourceRect.size = string?.boundingRect(with: rect.size, options: options, attributes: attributes, context: context).size ?? .zero
    }
}
public extension String {
    /// Convenience getter for string layout constraint.
    ///
    /// - Parameters:
    ///   - attributes: String attributes
    ///   - context: Drawing context
    /// - Returns: String-based constraint
    @available(OSX 10.11, iOS 10.0, *)
    func layoutConstraint(with options: String.DrawingOptions = .usesLineFragmentOrigin, attributes: [NSAttributedString.Key: Any]? = nil, context: NSStringDrawingContext? = nil) -> StringLayoutAnchor {
        return StringLayoutAnchor(string: self, options: options, attributes: attributes, context: context)
    }
}
#endif
