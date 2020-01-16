//
//  ViewController.swift
//  CGLayout-macOS
//
//  Created by Denis Koryttsev on 02/10/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Cocoa
import CGLayout

class ColoredView: NSView {
    var backgroundColor: NSColor? {
        didSet { setNeedsDisplay(bounds) }
    }

    override var wantsUpdateLayer: Bool { return true }

    override func updateLayer() {
        super.updateLayer()
        layer?.backgroundColor = backgroundColor?.cgColor;
    }
}

extension ViewController {
    func buildView<V: ColoredView>(_ type: V.Type, bg: NSColor) -> V {
        let v = V.init()
        v.backgroundColor = bg
        scrollView.documentView?.addSubview(v)
        return v
    }
    func buildView<V: NSView>(_ type: V.Type, bg: NSColor) -> V {
        let v = V.init()
//        v.backgroundColor = bg
        scrollView.documentView?.addSubview(v)
        return v
    }
}

extension ViewController {
    func addLayoutGuide(_ lg: LayoutGuide<NSView>) {
        scrollView.documentView?.add(layoutGuide: lg)
        layoutGuides.append(lg)
    }
}

final class FlippedView: NSView {
    override var isFlipped: Bool { return true }
}

class ViewController: NSViewController {
    var scrollView: NSScrollView { return view as! NSScrollView }
    var layoutGuides: [LayoutGuide<NSView>] = []

    lazy var scheme: LayoutScheme = self.buildScheme()

    override func loadView() {
        let view = NSScrollView()
        view.documentView = FlippedView()
        self.view = view
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        if let rect = view.window?.frame {
            scrollView.frame = NSRect(origin: .zero, size: rect.insetBy(dx: 0, dy: 10).size)
        }
        let snap = scheme.snapshot(for: view.frame)
        scrollView.documentView?.frame.size = snap.frame.size
        scheme.apply(snapshot: snap)
    }

    override func viewWillTransition(to newSize: NSSize) {
        super.viewWillTransition(to: newSize)
        scheme.layout()
    }

    func buildScheme() -> LayoutScheme {
        let headerView = buildView(ColoredView.self, bg: .white)
        let headerRightGroupGuide = StackLayoutGuide<NSView>() // cannot calcute size based on elements
        headerRightGroupGuide.scheme.direction = .fromTrailing
        headerRightGroupGuide.scheme.spacing = .equal(10)
        headerRightGroupGuide.scheme.filling = .equal(40)
        headerRightGroupGuide.contentInsets.right = 16
        layoutGuides.append(headerRightGroupGuide)
        headerView.add(layoutGuide: headerRightGroupGuide)
        let headerRightGroup = headerRightGroupGuide.layoutBlock { (anchors) in
            anchors.top.align(by: headerView.layoutAnchors.top)
            anchors.right.align(by: headerView.layoutAnchors.right)
            anchors.centerY.align(by: headerView.layoutAnchors.centerY)
            anchors.width.equalIntrinsicSize()
            anchors.height.equal(to: 40)
        }
        let hrb1Button = buildView(ColoredView.self, bg: .black)
        headerRightGroupGuide.addArranged(element: .uiView(hrb1Button))
        let hrb2Button = buildView(ColoredView.self, bg: .lightGray)
        headerRightGroupGuide.addArranged(element: .uiView(hrb2Button))
        let hrb3Button = buildView(ColoredView.self, bg: .lightGray)
        headerRightGroupGuide.addArranged(element: .uiView(hrb3Button))

        let header = LayoutScheme(blocks: [
            headerView.layoutBlock { (anchors) in
                anchors.top.align(by: view.layoutAnchors.top)
                anchors.height.equal(to: 64)
                anchors.width.equal(to: view.layoutAnchors.width)
            },
            headerRightGroup
        ])

        let avatarView = buildView(ColoredView.self, bg: .black)
        let avatar = avatarView.layoutBlock(with: Layout(y: .top(20))) { (anchors) in
            anchors.height.equal(to: 100)
            anchors.width.equal(to: 100)
            anchors.top.align(by: headerView.layoutAnchors.bottom)
            anchors.centerX.align(by: view.layoutAnchors.centerX)
        }

        let nameLabel = buildView(NSTextField.self, bg: .gray)
        nameLabel.font = NSFont.boldSystemFont(ofSize: 30)
        nameLabel.stringValue = "РЕШЕТЕЕВ НИКИТА"
        let name = nameLabel.layoutBlock(with: Layout(y: .top(10))) { (anchors) in
            anchors.top.align(by: avatarView.layoutAnchors.bottom)
            anchors.centerX.align(by: view.layoutAnchors.centerX)
            anchors.width.equalIntrinsicSize()
            anchors.height.equalIntrinsicSize()
        }

        let socialLabelPrefix = buildView(NSTextField.self, bg: .lightGray)
        socialLabelPrefix.font = NSFont.monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        socialLabelPrefix.stringValue = "@"
        let socialPrefix = socialLabelPrefix.layoutBlock(with: Layout(y: .top(8))) { (anchors) in
            anchors.top.align(by: nameLabel.layoutAnchors.bottom)
            anchors.centerX.align(by: view.layoutAnchors.centerX)
            anchors.width.equalIntrinsicSize()
            anchors.height.equalIntrinsicSize()
        }

        let socialLabel = buildView(NSTextField.self, bg: .lightGray)
        socialLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 16, weight: .light)
        socialLabel.stringValue = "Nikita_resh"
        // TODO: Baseline is unavailable in anchors
        /*
        let social = socialLabel.layoutBlock(constraints: { (anchors) in
            anchors.left.align(by: socialLabelPrefix.layoutAnchors.right)
//            anchors.baseline.align(by: socialLabelPrefix.layoutAnchors.baseline) // baseline does not working because block deals with label frame. need two blocks
            anchors.width.equalIntrinsicSize()
            anchors.height.equalIntrinsicSize()
        })
        let socialPosition = socialLabel.baselineElement.layoutBlock(constraints: { (anchors) in
            anchors.top.align(by: socialLabelPrefix.baselineElement.layoutAnchors.bottom)
//            anchors.left.align(by: socialLabelPrefix.layoutAnchors.right)
        })
         */
        let social = socialLabel.layoutBlock(constraints: [
            socialLabelPrefix.layoutConstraint(for: [.right(.limit(on: .outer))]),
            socialLabel.adjustLayoutConstraint(for: [.width(), .height()]),
        ])
        let socialPosition = socialLabel/*.baselineElement*/.layoutBlock(with: .vertical(.bottom()), constraints: [
//            socialLabelPrefix.baselineLayoutConstraint(for: [.bottom(.align(by: .inner))])
            socialLabelPrefix.layoutConstraint(for: [.bottom(.align(by: .inner))])
        ])

        let buttonsGroupGuide = StackLayoutGuide<NSView>() // cannot calcute size based on elements
        buttonsGroupGuide.scheme.direction = .fromCenter
        buttonsGroupGuide.scheme.spacing = .equal(10)
        buttonsGroupGuide.scheme.filling = .equal(130)
        addLayoutGuide(buttonsGroupGuide)
        let btnsGroup = buttonsGroupGuide.layoutBlock(with: Layout(y: .top(20))) { (anchors) in
            anchors.top.align(by: socialLabelPrefix.layoutAnchors.bottom)
            anchors.centerX.align(by: view.layoutAnchors.centerX)
            anchors.width.equalIntrinsicSize()
            anchors.height.equal(to: 40)
        }
        let btn1Button = buildView(ColoredView.self, bg: .black)
//        btn1Button.titleLabel?.font = NSFont.preferredFont(forTextStyle: .caption1)
//        btn1Button.setTitle("СМЕНИТЬ АВАТАР", for: .normal)
        buttonsGroupGuide.addArranged(element: .uiView(btn1Button))
        let btn2Button = buildView(ColoredView.self, bg: .lightGray)
//        btn2Button.titleLabel?.font = NSFont.preferredFont(forTextStyle: .caption1)
//        btn2Button.setTitle("УДАЛИТЬ", for: .normal)
        buttonsGroupGuide.addArranged(element: .uiView(btn2Button))

        let socialGroupGuide = StackLayoutGuide<NSView>() // cannot calcute size based on elements
        socialGroupGuide.scheme.direction = .fromCenter
        socialGroupGuide.scheme.spacing = .equal(10)
        socialGroupGuide.scheme.filling = .equal(40)
        addLayoutGuide(socialGroupGuide)
        let socialGroup = socialGroupGuide.layoutBlock(with: Layout(y: .top(15))) { (anchors) in
            anchors.top.align(by: buttonsGroupGuide.layoutAnchors.bottom)
            anchors.centerX.align(by: view.layoutAnchors.centerX)
            anchors.width.equalIntrinsicSize()
            anchors.height.equal(to: 40)
        }
        let scl1Button = buildView(ColoredView.self, bg: .black)
        socialGroupGuide.addArranged(element: .uiView(scl1Button))
        let scl2Button = buildView(ColoredView.self, bg: .lightGray)
        socialGroupGuide.addArranged(element: .uiView(scl2Button))
        let scl3Button = buildView(ColoredView.self, bg: .lightGray)
        socialGroupGuide.addArranged(element: .uiView(scl3Button))

        let title1Label = buildView(NSTextField.self, bg: .gray)
//        title1Label.font = NSFont.preferredFont(forTextStyle: .title3)
        title1Label.stringValue = "Обо мне"
        let title1 = title1Label.layoutBlock(with: Layout(y: .top(20))) { (anchors) in
            anchors.top.align(by: socialGroupGuide.layoutAnchors.bottom)
            anchors.centerX.align(by: view.layoutAnchors.centerX)
            anchors.width.equalIntrinsicSize()
            anchors.height.equalIntrinsicSize()
        }

        let bodyLabel = buildView(NSTextField.self, bg: .lightGray)
//        bodyLabel.numberOfLines = 0
//        bodyLabel.font = NSFont.preferredFont(forTextStyle: .body)
        bodyLabel.stringValue = "Бенефисы Самошникова на «Открытие Арене» и Алиева на «Арене Химки», четыре гола в меньшинстве «Текстильщика», Харитонов в роли Дзюбы, Черышев — в западне. 17 тур в ФНЛ получился ярким!"
        let body = bodyLabel.layoutBlock(with: Layout(y: .top(15))) { (anchors) in
            anchors.top.align(by: title1Label.layoutAnchors.bottom)
            anchors.centerX.align(by: view.layoutAnchors.centerX)
            anchors.left.limit(by: view.layoutAnchors.left)
            anchors.right.limit(by: view.layoutAnchors.right)
            anchors.width.equalIntrinsicSize()
            anchors.height.equalIntrinsicSize()
        }

        return LayoutScheme(blocks: [
            header, avatar, name, socialPrefix, social, socialPosition, btnsGroup, socialGroup, title1, body
        ])
    }
}

