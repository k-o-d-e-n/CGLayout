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
extension LayoutAnchor.Size {
    static func stringSize(_ string: String?,
                           options: NSStringDrawingOptions = .usesLineFragmentOrigin,
                           attributes: [String: Any],
                           context: NSStringDrawingContext? = nil) -> LayoutAnchor.Size {
        return .build(StringLayoutAnchor(string: string, options: options, attributes: attributes, context: context))
    }
}
extension LayoutAnchor.Center {
    static var centerTop: LayoutAnchor.Center { return .build(CenterTop()) }
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

    let rightLimit = LayoutAnchor.Right.limit(on: .outer)
    let leftLimit = LayoutAnchor.Left.limit(on: .outer)
    let bottomLimit = LayoutAnchor.Bottom.limit(on: .outer)
    let topLimit = LayoutAnchor.Top.limit(on: .inner)
    let bottomInnerAlign = LayoutAnchor.Bottom.align(by: .inner)
    let heightEqual = LayoutAnchor.Size.height()
    let widthEqual = LayoutAnchor.Size.width()

    let separatorSize = Layout.Filling(horizontal: .fixed(1), vertical: .scaled(1))
    let separator1Align = Layout.Alignment(horizontal: .right(25), vertical: .top())
    let separator2Align = Layout.Alignment(horizontal: .left(25), vertical: .bottom())

    lazy var rainLabelReservedConstraint: MutableLayoutConstraint = self.distanceLabel.layoutConstraint(for: [self.topLimit, LayoutAnchor.Left.align(by: .outer)]).active(false)
    lazy var presentationLabelBlock: LayoutBlock<UILabel> = self.presentationLabel.layoutBlock(with: Layout(x: .center(), y: .top(5), width: .scaled(1), height: .fixed(50)),
                                                                                               constraints: [self.nameLabel.layoutConstraint(for: [self.bottomLimit])])

    lazy var layoutScheme: LayoutScheme = {

        return LayoutScheme(blocks: [
            self.distanceLabel.layoutBlock(with: Layout(x: .center(), y: .bottom(50), width: .fixed(70), height: .fixed(30))),
            self.separator1Layer.layoutBlock(with: Layout(alignment: self.separator1Align, filling: self.separatorSize),
                                            constraints: [self.distanceLabel.layoutConstraint(for: [self.leftLimit, self.topLimit, self.heightEqual])]),
            self.separator2Layer.layoutBlock(with: Layout(alignment: self.separator2Align, filling: self.separatorSize),
                                            constraints: [self.distanceLabel.layoutConstraint(for: [self.heightEqual, self.rightLimit, self.bottomInnerAlign])]),
            self.weatherImageView.layoutBlock(with: Layout(x: .left(20), y: .top(), width: .fixed(30), height: .fixed(30)),
                                              constraints: [self.separator2Layer.layoutConstraint(for: [self.rightLimit, self.topLimit])]),
            self.weatherLabel.layoutBlock(with: Layout(x: .left(10), y: .top(), width: .scaled(1), height: .scaled(1)),
                                          constraints: [self.weatherImageView.layoutConstraint(for: [self.topLimit, self.rightLimit, self.heightEqual]),
                                                        self.weatherLabel.adjustLayoutConstraint(for: [self.widthEqual])]),
//                                            self.weatherLabel.adjustLayoutConstraint(for: [.stringSize(self.weatherLabel.text, attributes: [NSFontAttributeName: self.weatherLabel.font])])]),
            self.rainLabel.layoutBlock(with: Layout(x: .right(20), y: .top(), width: .scaled(1), height: .fixed(30)),
                                       constraints: [self.rainLabel.adjustLayoutConstraint(for: [self.widthEqual]),
                                                     self.separator1Layer.layoutConstraint(for: [self.topLimit, LayoutAnchor.Left.align(by: .outer)]),
                                                     self.rainLabelReservedConstraint]),
            self.rainImageView.layoutBlock(with: Layout(x: .right(10), y: .top(), width: .fixed(30), height: .fixed(30)),
                                           constraints: [self.rainLabel.layoutConstraint(for: [self.leftLimit, self.topLimit])]),
            self.logoImageView.layoutBlock(with: Layout(x: .center(), y: .top(80), width: .fixed(70), height: .fixed(70))),
            /// example including other scheme to top level scheme
            LayoutScheme(blocks: [
                self.titleLabel.layoutBlock(with: Layout(x: .center(), y: .top(5), width: .scaled(1), height: .fixed(120)),
                                            constraints: [self.logoImageView.layoutConstraint(for: [self.bottomLimit])]),
                self.nameLabel.layoutBlock(with: Layout(x: .center(), y: .center(20), width: .scaled(1), height: .fixed(30))),
                self.presentationLabelBlock
            ])
        ])
    }()

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
        DispatchQueue.global(qos: .background).async {
            let portraitSnapshot = self.layoutScheme.snapshot(for: isLandscape ? CGRect(x: 0, y: 0, width: bounds.height, height: bounds.width) : bounds)
            let landscapeSnapshot = self.layoutScheme.snapshot(for: isLandscape ? bounds : CGRect(x: 0, y: 0, width: bounds.height, height: bounds.width))
            DispatchQueue.main.sync {
                self.portraitSnapshot = portraitSnapshot
                self.landscapeSnapshot = landscapeSnapshot
                self.layoutScheme.apply(snapshot: UIDevice.current.orientation.isLandscape ? landscapeSnapshot : portraitSnapshot)
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
//        if UIDevice.current.orientation.isPortrait, let snapshot = portraitSnapshot {
//            layoutScheme.apply(snapshot: snapshot)
//        } else if UIDevice.current.orientation.isLandscape, let snapshot = landscapeSnapshot {
//            layoutScheme.apply(snapshot: snapshot)
//        } else {
            layoutScheme.layout()
//        }
        #endif
        #if os(tvOS)
            layoutScheme.layout()
        #endif
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        separator1Layer?.removeFromSuperItem()
        if !rainLabelReservedConstraint.isActive {
            presentationLabelBlock.setLayout(Layout(x: .center(), y: .center(), width: .scaled(1), height: .scaled(1)))
            presentationLabelBlock.setConstraints([presentationLabel.adjustLayoutConstraint(for: [.height()]),
                                                   view.layoutConstraint(for: [LayoutAnchor.Center.align(by: .center)])])
        }
        rainLabelReservedConstraint.isActive = true
    }
}

extension CALayer {
    convenience init(backgroundColor: UIColor) {
        self.init()
        self.backgroundColor = backgroundColor.cgColor
    }
}
