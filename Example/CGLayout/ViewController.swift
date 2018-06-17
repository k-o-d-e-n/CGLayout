//
//  ViewController.swift
//  CGLayout
//
//  Created by k-o-d-e-n on 08/31/2017.
//  Copyright (c) 2017 k-o-d-e-n. All rights reserved.
//

import UIKit
import CGLayout

class LabelPlaceholder: ViewPlaceholder<UILabel> {
    var font: UIFont?
    var textColor: UIColor?
    override var frame: CGRect {
        didSet { itemIfLoaded?.frame = frame }
    }

    open override func itemDidLoad() {
        super.itemDidLoad()

        item.font = font
        item.textColor = textColor
    }

    convenience init() {
        self.init(frame: .zero)
    }
    convenience init(font: UIFont, textColor: UIColor) {
        self.init()
        self.font = font
        self.textColor = textColor
    }
}

class ViewController: UIViewController {
    var scrollView: UIScrollView { return view as! UIScrollView }
    var subviews: [UIView] = []
    let pulledView: UIView = UIView()
    let centeredView: UIView = UIView()
    let navigationBarBackView = UIView()
    let subview = UIView()

    lazy var stackScheme: StackLayoutScheme = { [unowned self] in
        var stack = StackLayoutScheme { Array(self.subviews[0..<7]) }
        stack.axis = CGRectAxis.vertical
        stack.spacing = .equal(10)
//        stack.distribution = .fromBottom(spacing: 10)
        stack.direction = .fromTrailing
        stack.alignment = .leading(215)
//        stack.filling = .custom(Layout.Filling(horizontal: .boxed(235), vertical: .fixed(50)))
        stack.filling = .equal(50)

        return stack
    }()
    lazy var stackLayoutGuide: StackLayoutGuide<UIView> = {
        let stack = StackLayoutGuide<UIView>(frame: .zero)
        stack.scheme.axis = CGRectAxis.vertical
        stack.contentInsets.top = 5
//        stack.scheme.distribution = .fromTop(spacing: 5)
        stack.scheme.direction = .fromLeading
        stack.scheme.alignment = .leading(2)
//        stack.scheme.filling = .custom(Layout.Filling(horizontal: .boxed(4), vertical: .fixed(20)))
        stack.scheme.filling = .equal(20)

        return stack
    }()
    lazy var substackLayoutGuide: StackLayoutGuide<UIView> = {
        let stack = StackLayoutGuide<UIView>(frame: .zero)
//        stack.scheme.distribution = .equalSpacingHorizontal()
        stack.scheme.direction = .fromCenter
        stack.scheme.spacing = .equally
//        stack.scheme.filling = .custom(Layout.Filling(horizontal: .fixed(20), vertical: .scaled(1)))
        stack.scheme.filling = .equal(20)

        return stack
    }()
    lazy var labelStack: StackLayoutGuide<UIView> = {
        let stack = StackLayoutGuide<UIView>(frame: .zero)
        stack.scheme.axis = CGRectAxis.vertical
//        stack.scheme.distribution = .fromTop(spacing: 2)
        stack.scheme.direction = .fromLeading
//        stack.scheme.filling = .autoDimension(default: Layout.Filling(horizontal: .scaled(1), vertical: .fixed(1)))
        stack.scheme.filling = .equal(1)
        stack.contentInsets.bottom = 2

        return stack
    }()
    lazy var scrollLayoutGuide: ScrollLayoutGuide<UIView> = {
        return ScrollLayoutGuide(contentItem: self.labelStack, direction: .vertical)
    }()

    lazy var latestItemLayout = Layout(alignment: Layout.Alignment(horizontal: .left(15), vertical: .top(10)),
                                       filling: Layout.Filling(horizontal: .boxed(20), vertical: .fixed(30)))
    lazy var pulledLayout = Layout(x: .left(15), y: .top(10),
                                   width: .boxed(25), height: .boxed(20))
    lazy var bottomConstraint = LayoutAnchor.Bottom.limit(on: .inner)
    lazy var rightConstraint = LayoutAnchor.Right.limit(on: .outer)

    lazy var labelPlaceholder: LabelPlaceholder = LabelPlaceholder(font: .systemFont(ofSize: 24), textColor: .red)

    override func viewDidLoad() {
        super.viewDidLoad()

        subviews = (0..<10).map { i -> UIView in
            let view = UIView()
            view.backgroundColor = UIColor(white: (1 - (1 / max(0.5,CGFloat(i)))), alpha: 1 / max(0.5,CGFloat(i)))
            return view
        }
        subviews.forEach(view.addSubview)
        view.addSubview(pulledView)
        pulledView.backgroundColor = .red
        view.addSubview(centeredView)
        centeredView.backgroundColor = .yellow
        view.addSubview(navigationBarBackView)
        navigationBarBackView.backgroundColor = .black
        subview.backgroundColor = .red
        pulledView.addSubview(subview)

        view.add(layoutGuide: labelPlaceholder)
        pulledView.add(layoutGuide: stackLayoutGuide)
        pulledView.add(layoutGuide: labelStack)
        pulledView.add(layoutGuide: scrollLayoutGuide)
        stackLayoutGuide.addArrangedItem(UIView(backgroundColor: .brown))
        stackLayoutGuide.addArrangedItem(UIView(backgroundColor: .yellow))
        stackLayoutGuide.addArrangedItem(CALayer(backgroundColor: .green))
        stackLayoutGuide.addArrangedItem(substackLayoutGuide)
        substackLayoutGuide.addArrangedItem(UIView(backgroundColor: .brown))
        substackLayoutGuide.addArrangedItem(CALayer(backgroundColor: .yellow))
        substackLayoutGuide.addArrangedItem(UIView(backgroundColor: .green))

        labelStack.addArrangedItem(UILabel(text: "Some string"))
        labelStack.addArrangedItem(CALayer(backgroundColor: .black))
        labelStack.addArrangedItem(UILabel(text: "Lorem Ipsum - это текст-\"рыба\", часто используемый в печати и вэб-дизайне."))
        labelStack.addArrangedItem(CALayer(backgroundColor: .black))
        labelStack.addArrangedItem(UILabel(text: "В то время некий безымянный печатник создал большую коллекцию размеров и форм шрифтов, используя Lorem Ipsum для распечатки образцов."))
        labelStack.addArrangedItem(CALayer(backgroundColor: .black))

        scrollView.contentSize.height = view.frame.height.advanced(by: 2)
        scrollView.contentSize.width = view.frame.width

        /// CALayer can insert by any index (work as zIndex)
//        let testlayer = CALayer(frame: view.bounds)
//        testlayer.backgroundColor = UIColor.lightGray.withAlphaComponent(0.25).cgColor
//        view.layer.insertSublayer(testlayer, at: .max)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let constrainedRect = CGRect(origin: .zero, size: CGSize(width: 200, height: 0))
        stackScheme.layout()
        var preview = self.subviews[0..<7].last
        let lastPreview = self.subviews[0..<7].last
        subviews[7..<10].forEach { subview in
            let constraints: [ConstrainRect] = [(lastPreview!.frame, bottomConstraint), (constrainedRect, rightConstraint)]
            let constraint: [ConstrainRect] = preview === lastPreview ? [] : [(preview!.frame, rightConstraint)]
            latestItemLayout.apply(for: subview, use: constraints + constraint)
            preview = subview
        }

        let topConstraint: LayoutAnchor.Top = traitCollection.verticalSizeClass == .compact ? .pull(from: .outer) : .limit(on: .outer)

        labelPlaceholder.layoutBlock(with: Layout(x: .right(), y: .top(), width: .scaled(0.6), height: .fixed(100)), constraints: [(topLayoutGuide as! UIView).layoutConstraint(for: [LayoutAnchor.Bottom.align(by: .outer)])]).layout()

        pulledLayout.apply(for: pulledView, use: [((topLayoutGuide as! UIView).frame, LayoutAnchor.Bottom.limit(on: .outer)), (labelPlaceholder.frame, LayoutAnchor.Left.limit(on: .outer)),
                                                  (subviews[1].frame, LayoutAnchor.Left.limit(on: .outer)), (subviews.first!.frame, topConstraint)])
        Layout.equal.apply(for: stackLayoutGuide)

        subviews[7].semanticContentAttribute = .forceRightToLeft
//        let centeredViewLayout = centeredView.layoutBlock(with: Layout(x: .center(), y: .bottom(), width: .scaled(1), height: .scaled(1)),
//                                                          constraints: [subviews[7].anchorSizeConstraint(for: [.scaled(centeredView.superview!.anchors.size.anchor,
//                                                                                                                       by: subviews[7].anchors.size.anchor,
//                                                                                                                       scale: 0.5)]),
//                                                                        subviews[7].anchorPointConstraint(for: [.align(centeredView.superview!.anchors.leading.anchor,
//                                                                                                                       by: subviews[7].anchors.leading.anchor)])])

        let centeredViewLayout = centeredView.block { (anchors) in
            /// anchors should contains reference on view. `align` method should be mutating and to store binded anchors
//            anchors.center.align(by: subviews[7].anchors.center)
//            anchors.size.scaled(by: subviews[7].anchors.size, scale: 0.5)
            anchors.width.scaled(by: subviews[7].layoutAnchors.width, scale: 0.5)
            anchors.height.scaled(by: subviews[7].layoutAnchors.height, scale: 0.5)
//            anchors.size.equal(to: CGSize(width: 50, height: 20))
//            anchors.origin.align(by: subviews[7].anchors.origin)
            anchors.left.align(by: subviews[7].layoutAnchors.left)
            anchors.right.align(by: subviews[7].layoutAnchors.right)
            anchors.bottom.pull(to: subviews[7].layoutAnchors.bottom)
        }

        /// centeredView.layoutBlock(with: layout, constraints: [.align(.bottom, by: subview.bottom), .limit(.left, on: subview.right)])
        /// centeredView.anchors.bottom.align(by: subview.anchors.bottom) // -> LayoutConstraint contains only one limiter. // anchors should contains reference on view.
        /// centeredView.layoutBlock(constraints: [.align(.bottom, by: .bottom, on: subview)]) // -> LayoutBlock

//        centeredView.anchors.size.set(CGSize(width: 20, height: 30), for: &centeredView.frame)
//        centeredView.anchors.center.horizontal.offset(rect: &centeredView.frame, by: subviews[7].anchors.center.horizontal.get(for: subviews[7].frame))
//        centeredView.anchors.bottom.offset(rect: &centeredView.frame, by: subviews[7].anchors.bottom.get(for: subviews[7].frame))
        
        // layout using only constraints and constrain to view (UINavigationController.view) from other hierarchy space. 
        navigationBarBackView.layoutBlock(with: Layout.equal, constraints: [navigationController!.navigationBar.layoutConstraint(for: [LayoutAnchor.equal])]).layout()

        let subviewLayout = subview.layoutBlock(with: Layout(x: .center(), y: .center(), width: .fixed(50), height: .fixed(1)),
                            constraints: [centeredView.layoutConstraint(for: [LayoutAnchor.equal])])
        let subviewScheme = LayoutScheme(blocks: [centeredViewLayout, subviewLayout])
        let snapshotSubview = subviewScheme.snapshot(for: view.bounds, constrainRects: [(subviews[7], subviews[7].frame)]) /// example use constrain rects 
        subviewScheme.apply(snapshot: snapshotSubview)

        scrollLayoutGuide.layoutBlock(with: Layout.equal,
                                      constraints: [pulledView.layoutConstraint(for: [LayoutAnchor.Size.height(), LayoutAnchor.Size.width()])]).layout()
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panGesture(_:)))
        pan.require(toFail: scrollView.panGestureRecognizer)
        pulledView.addGestureRecognizer(pan)
    }

    var start: CGPoint = .zero
    @objc func panGesture(_ recognizer: UIPanGestureRecognizer) {
        var position: CGPoint = .zero
        let translation = recognizer.translation(in: recognizer.view)
        if recognizer.state == .began {
            start = scrollLayoutGuide.contentOffset
            position = start
        } else {
            position = CGPoint(x: start.x - translation.x, y: start.y - translation.y)
        }

        scrollLayoutGuide.contentOffset = position
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        labelPlaceholder.item.text = "Placeholder label"
    }
}

extension UIView {
    convenience init(backgroundColor: UIColor) {
        self.init()
        self.backgroundColor = backgroundColor
    }
}

extension UILabel {
    convenience init(text: String) {
        self.init()
        self.text = text
        self.numberOfLines = 0
    }
}
