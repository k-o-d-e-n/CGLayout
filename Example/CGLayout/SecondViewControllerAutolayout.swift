//
//  SecondViewControllerAutolayout.swift
//  CGLayout
//
//  Created by Denis Koryttsev on 18/09/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import CGLayout

open class UIAdjustViewPlaceholder<View: UIView>: UIViewPlaceholder<View> {
    open override func viewDidLoad() {
        super.viewDidLoad()
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.topAnchor.constraint(equalTo: topAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentHuggingPriority(.required, for: .vertical)
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
}

class SecondViewControllerAutolayout: UIViewController {
    lazy var placeholder: UIAdjustViewPlaceholder<UILabel> = .init()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addLayoutGuide(placeholder)
        NSLayoutConstraint.activate([
            placeholder.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            placeholder.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor)
        ])
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if !placeholder.isViewLoaded {
            placeholder.view.numberOfLines = 0
            placeholder.view.widthAnchor.constraint(equalToConstant: 100).isActive = true
        }
        placeholder.view.text = "Placeholder text"
    }

}
