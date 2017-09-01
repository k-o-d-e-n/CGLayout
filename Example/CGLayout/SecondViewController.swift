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

    lazy var logoImageViewLayout = Layout(x: .center(), y: .top(80), width: .constantly(70), height: .constantly(70))
    lazy var titleLabelLayout = Layout(x: .center(), y: .top(5), width: .scaled(1), height: .constantly(120))
    lazy var nameLabelLayout = Layout(x: .center(), y: .center(20), width: .scaled(1), height: .constantly(30))
    lazy var presentationLabelLayout = Layout(x: .center(), y: .top(5), width: .scaled(1), height: .constantly(50))
    lazy var rainLabelLayout = Layout(x: .right(20), y: .top(), width: .constantly(50), height: .constantly(30))
    lazy var rainImageViewLayout = Layout(x: .right(10), y: .top(), width: .constantly(30), height: .constantly(30))
    lazy var weatherLabelLayout = Layout(alignmentV: .top(), fillingV: .constantly(30),
                                         alignmentH: .left(10), fillingH: .scaled(1))
    lazy var weatherImageViewLayout = Layout(alignmentV: .top(), fillingV: .constantly(30),
                                             alignmentH: .left(20), fillingH: .constantly(30))
    lazy var distanceLabelLayout = Layout(alignmentV: .bottom(50), fillingV: .constantly(30),
                                          alignmentH: .center(), fillingH: .constantly(70))
    lazy var separatorSize = Layout.Filling(vertical: .constantly(30), horizontal: .constantly(1))
    lazy var separator1Align = Layout.Alignment(vertical: .top(), horizontal: .right(25))
    lazy var separator2Align = Layout.Alignment(vertical: .top(), horizontal: .left(25))
    lazy var rightAlign = LayoutAnchor.Right.limit(on: .outer)
    lazy var leftAlign = LayoutAnchor.Left.limit(on: .outer)
    lazy var bottomAlign = LayoutAnchor.Bottom.limit(on: .outer)
    lazy var topAlign = LayoutAnchor.Top.limit(on: .inner)

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        distanceLabelLayout.apply(for: distanceLabel)
        Layout(alignment: separator1Align, filling: separatorSize).apply(for: separator1View, use: [(distanceLabel.frame, leftAlign), (distanceLabel.frame, topAlign)])
        Layout(alignment: separator2Align, filling: separatorSize).apply(for: separator2View, use: [(distanceLabel.frame, rightAlign), (distanceLabel.frame, topAlign)])
        weatherImageViewLayout.apply(for: weatherImageView, use: [(separator2View.frame, rightAlign), (separator2View.frame, topAlign)])
        weatherLabelLayout.apply(for: weatherLabel, use: [(weatherImageView.frame, rightAlign), (weatherImageView.frame, topAlign)])
        rainLabelLayout.apply(for: rainLabel, use: [(separator1View.frame, leftAlign), (separator1View.frame, topAlign)])
        rainImageViewLayout.apply(for: rainImageView, use: [rainLabel.constraint(for: leftAlign), rainLabel.constraint(for: topAlign)])
        nameLabelLayout.apply(for: nameLabel)
        presentationLabelLayout.apply(for: presentationLabel, use: [nameLabel.constraint(for: bottomAlign)])
        logoImageViewLayout.apply(for: logoImageView)
        titleLabelLayout.apply(for: titleLabel, use: [logoImageView.constraint(for: bottomAlign)])
    }
}
