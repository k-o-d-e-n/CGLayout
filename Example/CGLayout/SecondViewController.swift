//
//  SecondViewController.swift
//  CGLayout
//
//  Created by Denis Koryttsev on 01/09/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import CGLayout

class SecondViewController: UIViewController {
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var presentationLabel: UILabel!
    @IBOutlet weak var rainImageView: UIImageView!
    @IBOutlet weak var rainLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var weatherImageView: UIImageView!
    @IBOutlet weak var weatherLabel: UILabel!
    @IBOutlet weak var separator1View: UIView!
    @IBOutlet weak var separator2View: UIView!

    let rightLimit = LayoutAnchor.Right.limit(on: .outer)
    let leftLimit = LayoutAnchor.Left.limit(on: .outer)
    let bottomLimit = LayoutAnchor.Bottom.limit(on: .outer)
    let topLimit = LayoutAnchor.Top.limit(on: .inner)
    let heightEqual = LayoutAnchor.Size.height()
    let widthEqual = LayoutAnchor.Size.width()

    let separatorSize = Layout.Filling(vertical: .scaled(1), horizontal: .constantly(1))
    let separator1Align = Layout.Alignment(vertical: .top(), horizontal: .right(25))
    let separator2Align = Layout.Alignment(vertical: .top(), horizontal: .left(25))

    lazy var layoutScheme: LayoutScheme = {
        return LayoutScheme(blocks: [
            self.distanceLabel.layoutBlock(with: Layout(x: .center(), y: .bottom(50), width: .constantly(70), height: .constantly(30))),
            self.separator1View.layoutBlock(with: Layout(alignment: self.separator1Align, filling: self.separatorSize),
                                            constraints: [self.distanceLabel.constraintItem(for: [self.leftLimit, self.topLimit, self.heightEqual])]),
            self.separator2View.layoutBlock(with: Layout(alignment: self.separator2Align, filling: self.separatorSize),
                                            constraints: [self.distanceLabel.constraintItem(for: [self.rightLimit, self.topLimit, self.heightEqual])]),
            self.weatherImageView.layoutBlock(with: Layout(x: .left(20), y: .top(), width: .constantly(30), height: .constantly(30)),
                                              constraints: [self.separator2View.constraintItem(for: [self.rightLimit, self.topLimit])]),
            self.weatherLabel.layoutBlock(with: Layout(x: .left(10), y: .top(), width: .scaled(1), height: .scaled(1)),
                                          constraints: [self.weatherImageView.constraintItem(for: [self.topLimit, self.rightLimit, self.heightEqual]),
                                                        self.weatherLabel.adjustedConstraintItem(for: [self.widthEqual]) // TODO: adjust constraint has unexpected behavior
                                            /*StringLayoutConstraint(string: self.weatherLabel.text, attributes: [NSFontAttributeName: self.weatherLabel.font])*/]),
            self.rainLabel.layoutBlock(with: Layout(x: .right(20), y: .top(), width: .scaled(1), height: .constantly(30)),
                                       constraints: [self.separator1View.constraintItem(for: [self.leftLimit, self.topLimit]),
                                                     self.rainLabel.adjustedConstraintItem(for: [self.widthEqual])]),
            self.rainImageView.layoutBlock(with: Layout(x: .right(10), y: .top(), width: .constantly(30), height: .constantly(30)),
                                           constraints: [self.rainLabel.constraintItem(for: [self.leftLimit, self.topLimit])]),
            self.nameLabel.layoutBlock(with: Layout(x: .center(), y: .center(20), width: .scaled(1), height: .constantly(30))),
            self.presentationLabel.layoutBlock(with: Layout(x: .center(), y: .top(5), width: .scaled(1), height: .constantly(50)),
                                               constraints: [self.nameLabel.constraintItem(for: [self.bottomLimit])]),
            self.logoImageView.layoutBlock(with: Layout(x: .center(), y: .top(80), width: .constantly(70), height: .constantly(70))),
            self.titleLabel.layoutBlock(with: Layout(x: .center(), y: .top(5), width: .scaled(1), height: .constantly(120)),
                                        constraints: [self.logoImageView.constraintItem(for: [self.bottomLimit])])
        ])
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        layoutScheme.layout()
    }
}
