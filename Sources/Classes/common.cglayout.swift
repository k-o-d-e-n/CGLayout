//
//  CommonExtensions.swift
//  CGLayout
//
//  Created by Denis Koryttsev on 04/09/2017.
//  Copyright © 2017 K-o-D-e-N. All rights reserved.
//

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import Cocoa
#elseif os(Linux)
import Foundation
#endif

internal func debugAction(_ action: () -> Void) {
    #if DEBUG
        action()
    #endif
}

internal func debugLog(_ message: String, _ file: String = #file, _ line: Int = #line) {
    debugAction {
        debugPrint("File: \(file)")
        debugPrint("Line: \(line)")
        debugPrint("Message: \(message)")
    }
}

internal func debugWarning(_ message: String) {
    debugWarning(true, message)
}

internal func debugWarning(_ condition: @autoclosure () -> Bool, _ message: String) {
    debugAction {
        if condition() {
            debugPrint("CGLayout WARNING: \(message)")
            if ProcessInfo.processInfo.arguments.contains("CGL_THROW_ON_WARNING") { fatalError() }
        }
    }
}

internal func debugFatalError(_ condition: @autoclosure () -> Bool = true,
                              _ message: String = "", _ file: String = #file, _ line: Int = #line) {
    debugAction {
        if condition() {
            debugLog(message, file, line)
            fatalError(message)
        }
    }
}

@discardableResult
func syncGuard<T>(mainThread action: @autoclosure () -> T) -> T {
    return _syncGuard(action)
}

@discardableResult
func syncGuard<T>(mainThread action: () -> T) -> T {
    return _syncGuard(action)
}

@discardableResult
func _syncGuard<T>(_ action: () -> T) -> T {
    #if os(iOS) || os(tvOS) || os(macOS)
        if !Thread.isMainThread {
            return DispatchQueue.main.sync(execute: action)
        } else {
            return action()
        }
    #else
        return action()
    #endif
}

#if os(iOS) || os(tvOS)
    public typealias EdgeInsets = UIEdgeInsets
#endif
#if os(macOS) || os(Linux)
    public typealias EdgeInsets = NSEdgeInsets
#endif

func -(l: CGSize, r: CGFloat) -> CGSize { return CGSize(width: l.width - r, height: l.height - r) }
func +(l: CGSize, r: CGFloat) -> CGSize { return CGSize(width: l.width + r, height: l.height + r) }
func *(l: CGSize, r: CGFloat) -> CGSize { return CGSize(width: l.width * r, height: l.height * r) }

extension CGPoint {
    func positive() -> CGPoint { return CGPoint(x: abs(x), y: abs(y)) }
    func negated() -> CGPoint { return CGPoint(x: -x, y: -y) }
}

extension CGRect {
    var left: CGFloat { return minX }
    var right: CGFloat { return maxX }
    var top: CGFloat { return minY }
    var bottom: CGFloat { return maxY }
    
    var distanceFromOrigin: CGSize { return CGSize(width: maxX, height: maxY) }
    func distance(from point: CGPoint) -> CGSize { return CGSize(width: maxX - point.x, height: maxY - point.y) }
}
extension CGRect {
    mutating func apply(edgeInsets: EdgeInsets) {
        self = EdgeInsetsInsetRect(self, edgeInsets)
    }
    func applying(edgeInsets: EdgeInsets) -> CGRect { var this = self; this.apply(edgeInsets: edgeInsets); return this }

    public func asLayout() -> Layout { return Layout(x: .left(origin.x), y: .top(origin.y), width: .fixed(width), height: .fixed(height)) }
}

func EdgeInsetsInsetRect(_ rect: CGRect, _ edgeInsets: EdgeInsets) -> CGRect {
    #if os(iOS) || os(tvOS)
        return UIEdgeInsetsInsetRect(rect, edgeInsets)
    #else
        return CGRect(x: rect.origin.x + edgeInsets.left, y: rect.origin.y + edgeInsets.top,
                      width: rect.size.width - edgeInsets.horizontal, height: rect.size.height - edgeInsets.vertical)
    #endif
}

#if os(macOS) || os(Linux)
extension EdgeInsets: Equatable {
    public static func ==(lhs: EdgeInsets, rhs: EdgeInsets) -> Bool {
        return lhs.left == rhs.left && lhs.right == rhs.right 
            && lhs.top == rhs.top && lhs.bottom == rhs.bottom
    }
}
#endif

extension EdgeInsets {
    var horizontal: CGFloat { return left + right }
    var vertical: CGFloat { return top + bottom }
#if os(macOS) || os(Linux)
    public static var zero: EdgeInsets { return EdgeInsets(top: 0, left: 0, bottom: 0, right: 0) }
#endif
}

#if os(iOS) || os(tvOS)
@available(iOS 9.0, *)
extension UILayoutGuide: LayoutElement {
    @objc open var layoutBounds: CGRect { return bounds }
    public var inLayoutTime: ElementInLayoutTime { return _MainThreadItemInLayoutTime(item: self) }
    @objc open var frame: CGRect { get { return layoutFrame } set {} }
    @objc open var bounds: CGRect { get { return CGRect(origin: .zero, size: layoutFrame.size) } set {} }
    public var superElement: LayoutElement? { return owningView }
    @objc open func removeFromSuperElement() { owningView.map { $0.removeLayoutGuide(self) } }
}
#endif

#if os(macOS) || os(iOS) || os(tvOS)
public extension CALayer {
    convenience init(frame: CGRect) {
        self.init()
        self.frame = frame
    }
}
#endif

extension Bool {
    mutating func `switch`() {
        self = self ? false : true
    }
}
