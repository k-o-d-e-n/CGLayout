//
//  ProfileViewController.swift
//  CGLayout_Example
//
//  Created by Denis Koryttsev on 12/10/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import CGLayout

extension UIViewController {
    func buildView<V: UIView>(_ type: V.Type, bg: UIColor) -> V {
        let v = V.init()
        v.backgroundColor = bg
        view.addSubview(v)
        return v
    }
}

extension ProfileViewController {
    func addLayoutGuide(_ lg: LayoutGuide<UIView>) {
        view.add(layoutGuide: lg)
        layoutGuides.append(lg)
    }
}

class ProfileViewController: UIViewController {
    var scheme: LayoutScheme!
    var layoutGuides: [LayoutGuide<UIView>] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        let headerView = buildView(UIView.self, bg: .white)
        let headerRightGroupGuide = StackLayoutGuide<UIView>()
        headerRightGroupGuide.scheme.direction = .fromTrailing
        headerRightGroupGuide.scheme.spacing = .equal(10)
        headerRightGroupGuide.scheme.filling = .equal(40)
        headerRightGroupGuide.contentInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        layoutGuides.append(headerRightGroupGuide)
        headerView.add(layoutGuide: headerRightGroupGuide)
        let headerRightGroup = headerRightGroupGuide.layoutBlock(
            constraints: { (anchors) in
                anchors.centerY.align(by: headerView.layoutAnchors.centerY)
                anchors.width.equalIntrinsicSize()
                anchors.height.equal(to: 40)
            }
        )
        let hrb1Button = buildView(UIButton.self, bg: .black)
        headerRightGroupGuide.addArrangedElement(hrb1Button)
        let hrb2Button = buildView(UIButton.self, bg: .lightGray)
        headerRightGroupGuide.addArrangedElement(hrb2Button)
        let hrb3Button = buildView(UIButton.self, bg: .lightGray)
        headerRightGroupGuide.addArrangedElement(hrb3Button)

        let header = LayoutScheme(blocks: [
            headerView.layoutBlock { (anchors) in
                if #available(iOS 11.0, tvOS 11.0, *) {
                    anchors.top.align(by: view.safeAreaLayoutGuide.layoutAnchors.top)
                } else {
                    anchors.top.align(by: navigationController!.navigationBar.layoutAnchors.bottom)
                }
                anchors.height.equal(to: 64)
                anchors.width.equal(to: view.layoutAnchors.width)
            },
            headerRightGroup
        ])

        let avatarView = buildView(UIImageView.self, bg: .gray)
        let avatar = avatarView.layoutBlock(with: Layout(y: .top(20))) { (anchors) in
            anchors.height.equal(to: 100)
            anchors.width.equal(to: 100)
            anchors.top.align(by: headerView.layoutAnchors.bottom)
            anchors.centerX.align(by: view.layoutAnchors.centerX)
        }

        let nameLabel = buildView(UILabel.self, bg: .gray)
        nameLabel.font = UIFont.boldSystemFont(ofSize: 30)
        nameLabel.text = "A SUPER MAN"
        let name = nameLabel.layoutBlock(with: Layout(y: .top(10))) { (anchors) in
            anchors.top.align(by: avatarView.layoutAnchors.bottom)
            anchors.centerX.align(by: view.layoutAnchors.centerX)
            anchors.width.equalIntrinsicSize()
            anchors.height.equalIntrinsicSize()
        }

        let socialLabelPrefix = buildView(UILabel.self, bg: .lightGray)
        socialLabelPrefix.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        socialLabelPrefix.text = "@"
        let socialPrefix = socialLabelPrefix.layoutBlock(with: Layout(y: .top(8))) { (anchors) in
            anchors.top.align(by: nameLabel.layoutAnchors.bottom)
            anchors.centerX.align(by: view.layoutAnchors.centerX)
            anchors.width.equalIntrinsicSize()
            anchors.height.equalIntrinsicSize()
        }

        let socialLabel = buildView(UILabel.self, bg: .lightGray)
        socialLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .light)
        socialLabel.text = "super_man"
        
        let social = socialLabel.layoutBlock(
            constraints: { (anchors) in
                anchors.leading.pull(to: socialLabelPrefix.layoutAnchors.trailing)
                // TODO: Baseline is unavailable in anchors
    //            anchors.baseline.align(by: socialLabelPrefix.layoutAnchors.baseline) // baseline does not working because block deals with label frame. need two blocks
                anchors.height.equalIntrinsicSize()
                anchors.width.equalIntrinsicSize(alignment: Layout.Alignment(horizontal: .leading(), vertical: .top()))
            }
        )
        let socialPosition = socialLabel.baselineElement.layoutBlock(
            with: Layout.nothing.with(y: .bottom()),
            constraints: { (anchors) in
                anchors.bottom.align(by: socialLabelPrefix.baselineElement.layoutAnchors.bottom)
            }
        )

        let buttonsGroupGuide = StackLayoutGuide<UIView>() // cannot calcute size based on elements
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
        let btn1Button = buildView(UIButton.self, bg: .black)
        btn1Button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .caption1)
        btn1Button.setTitle("CHANGE", for: .normal)
        buttonsGroupGuide.addArrangedElement(btn1Button)
        let btn2Button = buildView(UIButton.self, bg: .lightGray)
        btn2Button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .caption1)
        btn2Button.setTitle("DELETE", for: .normal)
        buttonsGroupGuide.addArrangedElement(btn2Button)

        let socialGroupGuide = StackLayoutGuide<UIView>() // cannot calcute size based on elements
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
        let scl1Button = buildView(UIButton.self, bg: .black)
        socialGroupGuide.addArrangedElement(scl1Button)
        let scl2Button = buildView(UIButton.self, bg: .lightGray)
        socialGroupGuide.addArrangedElement(scl2Button)
        let scl3Button = buildView(UIButton.self, bg: .lightGray)
        socialGroupGuide.addArrangedElement(scl3Button)

        let title1Label = buildView(UILabel.self, bg: .gray)
        title1Label.font = UIFont.preferredFont(forTextStyle: .title3)
        title1Label.text = "About me"
        let title1 = title1Label.layoutBlock(with: Layout(y: .top(20))) { (anchors) in
            anchors.top.align(by: socialGroupGuide.layoutAnchors.bottom)
            anchors.centerX.align(by: view.layoutAnchors.centerX)
            anchors.width.equalIntrinsicSize()
            anchors.height.equalIntrinsicSize()
        }

        let bodyLabel = buildView(UILabel.self, bg: .lightGray)
        bodyLabel.numberOfLines = 0
        bodyLabel.font = UIFont.preferredFont(forTextStyle: .body)
        bodyLabel.text = "The purpose of lorem ipsum is to create a natural looking block of text (sentence, paragraph, page, etc.) that doesn't distract from the layout. A practice not without controversy, laying out pages with meaningless filler text can be very useful when the focus is meant to be on design, not content"
        let body = bodyLabel.layoutBlock(with: Layout(y: .top(15))) { (anchors) in
            anchors.top.align(by: title1Label.layoutAnchors.bottom)
            anchors.centerX.align(by: view.layoutAnchors.centerX)
            if #available(iOS 11.0, tvOS 11.0, *) {
                anchors.leading.limit(by: view.safeAreaLayoutGuide.layoutAnchors.leading)
                anchors.trailing.limit(by: view.safeAreaLayoutGuide.layoutAnchors.trailing)
            } else {
            }
            anchors.width.equalIntrinsicSize()
            anchors.height.equalIntrinsicSize()
        }

        scheme = LayoutScheme(blocks: [
            header, avatar, name, socialPrefix, social, socialPosition, btnsGroup, socialGroup, title1, body
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scheme.layout(in: view.bounds)
    }
}
