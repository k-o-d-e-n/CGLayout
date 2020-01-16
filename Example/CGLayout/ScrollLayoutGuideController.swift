//
//  ScrollLayoutViewController.swift
//  CGLayout
//
//  Created by Denis Koryttsev on 15/10/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import CGLayout

extension UIViewController {
    func loadContentScheme(subviews: inout [UIView]) -> (scheme: LayoutScheme, guide: LayoutGuide<UIView>) {
        let redView = UIView(backgroundColor: .red)
        subviews.append(redView)
        let greenView = UIView(backgroundColor: .green)
        subviews.append(greenView)
        let blueView = UIView(backgroundColor: .blue)
        subviews.append(blueView)
        let contentGuide = LayoutGuide<UIView>(frame: view.bounds.insetBy(dx: -100, dy: -300))

//        let contentLayer = CALayer()
//        contentLayer.actions = ["position" : NSNull(), "bounds" : NSNull(), "path" : NSNull()]
//        contentLayer.borderWidth = 1
//        view.layer.addSublayer(contentLayer)

        return (
            scheme: LayoutScheme(blocks: [
                contentGuide.layoutBlock(with: Layout(x: .left(), y: .top(), width: .fixed(contentGuide.frame.width), height: .fixed(contentGuide.frame.height))),
                redView.layoutBlock(with: Layout(x: .left(), y: .top(), width: .fixed(200), height: .fixed(150))),
                blueView.layoutBlock(with: Layout(x: .center(), y: .center(), width: .fixed(200), height: .fixed(200))),
                greenView.layoutBlock(with: Layout(x: .left(), y: .bottom(), width: .fixed(150), height: .fixed(200)),
                                      constraints: [contentGuide.layoutConstraint(for: [LayoutAnchor.left(.align(by: .inner)), LayoutAnchor.bottom(.align(by: .inner))])]),
//                contentLayer.layoutBlock()
            ]),
            guide: contentGuide
        )
    }
}

class ScrollLayoutGuideController: UIViewController {
    var scrollLayoutGuide: ScrollLayoutGuide<UIView>!

    var subviews: [UIView] = []
    var scheme: LayoutScheme!

    override func viewDidLoad() {
        super.viewDidLoad()

        let content = loadContentScheme(subviews: &subviews)
        
        scrollLayoutGuide = ScrollLayoutGuide(layout: content.scheme)
        scrollLayoutGuide.contentSize = content.guide.bounds.size
        scheme = LayoutScheme(blocks: [
            scrollLayoutGuide.layoutBlock(
                with: Layout(x: .left(), y: .top(), width: .scaled(1), height: .scaled(1)),
                constraints: [(topLayoutGuide as! UIView).layoutConstraint(for: [LayoutAnchor.bottom(.limit(on: .outer))])]
            ),
            content.scheme
        ])

        view.add(layoutGuide: scrollLayoutGuide)
        view.add(layoutGuide: content.guide)
        subviews.forEach({ view.addSubview($0) })

        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panGesture(_:))))

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Native", style: .plain, target: self, action: #selector(openNative))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scheme.layout()
    }

    var start: CGPoint = .zero
    var timer: Timer? = nil
    @objc func panGesture(_ recognizer: UIPanGestureRecognizer) {
        let velocity = recognizer
                        .velocity(in: recognizer.view)
                        .clamped(max: 1500)

        switch recognizer.state {
        case .began:
            timer?.invalidate()
            timer = nil
            start = scrollLayoutGuide.contentOffset
        case .changed:
            let translation = recognizer.translation(in: recognizer.view)
            _ = scrollLayoutGuide.decelerate(start: start, translation: translation, velocity: velocity)
        case .ended:
            if let animation = scrollLayoutGuide.decelerate(start: start, translation: nil, velocity: velocity) {
                if #available(iOS 10.0, *) {
                    timer?.invalidate()
                    timer = Timer(timeInterval: 1/60, repeats: true, block: { timer in
                        if animation.step() {
                            timer.invalidate()
                        }
                    })
                    RunLoop.current.add(timer!, forMode: .default)
                } else {
                    // Fallback on earlier versions
                }
            }
        default: break
        }
    }

    @objc func openNative() {
        let vc = UIScrollViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension CGPoint {
    func clamped(max: CGFloat) -> CGPoint {
        return CGPoint(x: clamp(x, min: -max, max: max), y: clamp(y, min: -max, max: max))
    }
    private func clamp(_ v: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        return (v < min) ? min : (v > max) ? max : v
    }
}

final class UIScrollViewController: UIViewController {
    var subviews: [UIView] = []
    var scheme: LayoutScheme!

    override func loadView() {
        view = UIScrollView(frame: UIScreen.main.bounds)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        let content = loadContentScheme(subviews: &subviews)
        scheme = LayoutScheme(blocks: [
            content.scheme
        ])
        (view as! UIScrollView).contentSize = content.guide.bounds.size

        view.add(layoutGuide: content.guide)
        subviews.forEach({ view.addSubview($0) })
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scheme.layout()
    }
}
