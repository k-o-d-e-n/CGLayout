//
//  SecondViewController.swift
//  CGLayout
//
//  Created by Denis Koryttsev on 01/09/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import CGLayout

/// Example extending
extension Size {
    static func stringSize(_ string: String?,
                           options: NSStringDrawingOptions = .usesLineFragmentOrigin,
                           attributes: [NSAttributedString.Key: Any],
                           context: NSStringDrawingContext? = nil) -> Size {
        return .build(StringLayoutAnchor(string: string, options: options, attributes: attributes, context: context))
    }
}
extension Center {
    static var centerTop: Center { return .build(CenterTop()) }
    private struct CenterTop: RectBasedConstraint {
        func formConstrain(sourceRect: inout CGRect, by rect: CGRect) {
            sourceRect.origin.x = rect.midX - (sourceRect.width / 2)
            sourceRect.origin.y = rect.midY
        }
    }
}

public class SecondViewController: UIViewController {
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var presentationLabel: UILabel!
    @IBOutlet weak var rainImageView: UIImageView!
    @IBOutlet weak var rainLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var weatherImageView: UIImageView!
    @IBOutlet weak var weatherLabel: UILabel!
    weak var separator1Layer: CALayer!
    weak var separator2Layer: CALayer!

    lazy var layoutScheme: LayoutScheme = buildScheme()

    var portraitSnapshot: LayoutSnapshotProtocol!
    var landscapeSnapshot: LayoutSnapshotProtocol!

    override public func viewDidLoad() {
        super.viewDidLoad()

        let separator1 = CALayer(backgroundColor: .black)
        view.layer.addSublayer(separator1)
        separator1Layer = separator1
        let separator2 = CALayer(backgroundColor: .black)
        view.layer.addSublayer(separator2)
        separator2Layer = separator2

        #if os(iOS)
        let bounds = view.bounds
        let isLandscape = UIDevice.current.orientation.isLandscape
        let scheme = self.layoutScheme
        DispatchQueue.global(qos: .background).async {
            let portraitSnapshot = scheme.snapshot(for: isLandscape ? CGRect(x: 0, y: 0, width: bounds.height, height: bounds.width) : bounds)
            let landscapeSnapshot = scheme.snapshot(for: isLandscape ? bounds : CGRect(x: 0, y: 0, width: bounds.height, height: bounds.width))
            DispatchQueue.main.sync {
                self.portraitSnapshot = portraitSnapshot
                self.landscapeSnapshot = landscapeSnapshot
                scheme.apply(snapshot: UIDevice.current.orientation.isLandscape ? landscapeSnapshot : portraitSnapshot)
            }
        }
        #endif
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // layout directly
//        layoutScheme.layout()

        // layout in background
//        let bounds = view.bounds
//        DispatchQueue.global(qos: .background).async {
//            let snapshot = self.layoutScheme.snapshot(for: bounds)
//            DispatchQueue.main.sync {
//                self.layoutScheme.apply(snapshot: snapshot)
//            }
//        }

        // cached layout
        #if os(iOS)
        if UIDevice.current.orientation.isPortrait, let snapshot = portraitSnapshot {
            layoutScheme.apply(snapshot: snapshot)
        } else if UIDevice.current.orientation.isLandscape, let snapshot = landscapeSnapshot {
            layoutScheme.apply(snapshot: snapshot)
        } else {
            layoutScheme.layout()
        }
        #endif
        #if os(tvOS)
            layoutScheme.layout()
        #endif
    }

    func buildScheme() -> LayoutScheme {
        return LayoutScheme(blocks: [
            distanceLabel.layoutBlock(with: Layout(x: .center(), y: .bottom(50), width: .fixed(70), height: .fixed(30))),
            separator1Layer.layoutBlock(
                with: Layout(x: .right(25), y: .top(), width: .fixed(1), height: .scaled(1)),
                constraints: [distanceLabel.layoutConstraint(for: [.left(.limit(on: .outer)), .top(.limit(on: .inner)), .size(.height())])]
            ),
            separator2Layer.layoutBlock(
                with: Layout(x: .left(25), y: .bottom(), width: .fixed(1), height: .scaled(1)),
                constraints: [distanceLabel.layoutConstraint(for: [.size(.height()), .right(.limit(on: .outer)), .bottom(.align(by: .inner))])]
            ),
            weatherImageView.layoutBlock(
                with: Layout(x: .left(20), y: .top(), width: .fixed(30), height: .fixed(30)),
                constraints: [separator2Layer.layoutConstraint(for: [.right(.limit(on: .outer)), .top(.limit(on: .inner))])]
            ),
            weatherLabel.layoutBlock(
                with: Layout(x: .left(10), y: .top(), width: .scaled(1), height: .scaled(1)),
                constraints: [
                    weatherImageView.layoutConstraint(for: [.top(.limit(on: .inner)), .right(.limit(on: .outer)), .size(.height())]),
                    weatherLabel.adjustLayoutConstraint(for: [.width()])
                ]
            ),
            rainLabel.layoutBlock(
                with: Layout(x: .right(20), y: .top(), width: .scaled(1), height: .fixed(30)),
                constraints: [
                    rainLabel.adjustLayoutConstraint(for: [.width()]),
                    separator1Layer.layoutConstraint(for: [.top(.limit(on: .inner)), .left(.align(by: .outer))])
                ]
            ),
            rainImageView.layoutBlock(
                with: Layout(x: .right(10), y: .top(), width: .fixed(30), height: .fixed(30)),
                constraints: [rainLabel.layoutConstraint(for: [.left(.limit(on: .outer)), .top(.limit(on: .inner))])]
            ),
            logoImageView.layoutBlock(
                with: Layout(x: .center(), y: .top(80), width: .fixed(70), height: .fixed(70)),
                constraints: [view.safeAreaLayoutGuide.layoutConstraint(for: [.top(.limit(on: .inner))])]
            ),
            /// example including other scheme to top level scheme
            LayoutScheme(blocks: [
                titleLabel.layoutBlock(
                    with: Layout(x: .center(), y: .top(5), width: .scaled(1), height: .fixed(120)),
                    constraints: [logoImageView.layoutConstraint(for: [.bottom(.limit(on: .outer))])]
                ),
                nameLabel.layoutBlock(with: Layout(x: .center(), y: .center(20), width: .scaled(1), height: .fixed(30))),
                presentationLabel.layoutBlock(
                    with: Layout(x: .center(), y: .top(20), width: .equal, height: .equal),
                    constraints: [
                        nameLabel.layoutConstraint(for: [.bottom(.limit(on: .outer))]),
                        presentationLabel.adjustLayoutConstraint(for: [.height()])
                    ]
                )
            ])
        ])
    }
}

extension CALayer {
    convenience init(backgroundColor: UIColor) {
        self.init()
        self.backgroundColor = backgroundColor.cgColor
    }
}
