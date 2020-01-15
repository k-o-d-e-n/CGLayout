//
//  TableViewController.swift
//  CGLayout
//
//  Created by Denis Koryttsev on 21/09/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import CGLayout

struct IfBetween: RectBasedLayout {
    let axis: RectAxis
    let space: ClosedRange<CGFloat>
    let modifier: (CGFloat) -> CGFloat
    func formLayout(rect: inout CGRect, in source: CGRect) {
        let size = axis.get(sizeAt: source)
        if space.contains(size) {
            axis.set(size: modifier(size), for: &rect)
        }
    }
}

extension Layout.Filling.Vertical {
    static func `if`(between: ClosedRange<CGFloat>, modifier: @escaping (CGFloat) -> CGFloat) -> Layout.Filling.Vertical {
        return .build(IfBetween(axis: CGRectAxis.vertical, space: between, modifier: modifier))
    }
}
extension Layout.Filling.Horizontal {
    static func `if`(between: ClosedRange<CGFloat>, modifier: @escaping (CGFloat) -> CGFloat) -> Layout.Filling.Horizontal {
        return .build(IfBetween(axis: CGRectAxis.horizontal, space: between, modifier: modifier))
    }
}

class TextCell: UITableViewCell {
    weak var label: UILabel!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        let label = UILabel()
        label.lineBreakMode = .byWordWrapping
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        contentView.addSubview(label)
        self.label = label
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// TODO: Add convenience entity for layout reuseable views, and calculation metrics based on content.
struct ReuseLayoutBlock {
    let layout: RectBasedLayout
    let targetConstraints: [RectBasedConstraint]
    let contentConstraints: [RectBasedConstraint]

    func contentRect(fitting rect: CGRect) -> CGRect {
        return contentConstraints.reduce(rect) { $1.constrained(sourceRect: $0, by: rect) }
    }
    func apply(for item: LayoutElement) {
        layout.apply(for: item, use: [(item.superElement!.bounds, targetConstraints)])
    }
}

class TableViewController: UITableViewController {
    let strings = "Lorem Ipsum - это текст-\"рыба\", часто используемый в печати и вэб-дизайне. Lorem Ipsum является стандартной \"рыбой\" для текстов на латинице с начала XVI века. В то время некий безымянный печатник создал большую коллекцию размеров и форм шрифтов, используя Lorem Ipsum для распечатки образцов. Lorem Ipsum не только успешно пережил без заметных изменений пять веков, но и перешагнул в электронный дизайн. Его популяризации в новое время послужили публикация листов Letraset. С образцами Lorem Ipsum в 60-х годах. В более недавнее время, программы электронной вёрстки типа Aldus PageMaker. В шаблонах которых используется Lorem Ipsum".components(separatedBy: ". ")

    let bottomView = UIView()
    let bottomView2 = UIView()
    let bottomView3 = UIView()
    let top1View = UIView()
    let layoutGuide = LayoutGuide<UITableView>(frame: UIScreen.main.bounds.insetBy(dx: 0, dy: 200))
    lazy var scheme = self.buildScheme()

    @available(iOS 10.0, *)
    lazy var blocks: [ReuseLayoutBlock] = self.strings.map {
        ReuseLayoutBlock(
            layout: Layout.equal,
            targetConstraints: [Inset(UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20))],
            contentConstraints: [
                Inset(UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)),
                $0.layoutConstraint(attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)]),
                Inset(UIEdgeInsets(top: -10, left: 0, bottom: -10, right: 0))
            ]
        )
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(TextCell.self, forCellReuseIdentifier: "reuseIdentifier")
        top1View.backgroundColor = .black
        bottomView.backgroundColor = .red
        bottomView2.backgroundColor = .yellow
        bottomView3.backgroundColor = .green
        bottomView3.layer.borderWidth = 1
        tableView.addSubview(top1View)
        tableView.addSubview(bottomView)
        tableView.addSubview(bottomView2)
        tableView.addSubview(bottomView3)
        tableView.add(layoutGuide: layoutGuide)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scheme.layout(in: view.frame)
    }

    private func buildScheme() -> LayoutScheme {
        let topLayoutGuideConstraint: LayoutConstraint
        if #available(iOS 11.0, tvOS 11.0, *) {
            topLayoutGuideConstraint = view.safeAreaLayoutGuide.layoutConstraint(for: [.top(.pull(from: .inner))])
        } else {
            topLayoutGuideConstraint = navigationController!.navigationBar.layoutConstraint(for: [.bottom(.pull(from: .outer))])
        }
        return LayoutScheme(blocks: [
            top1View.layoutBlock( // pull to refresh
                with: Layout(
                    x: .center(), y: .center(),
                    width: .scaled(0.8) + .if(between: 375...767, modifier: { $0 * 0.6 }) + .if(between: 768...1366, modifier: { $0 * 0.4 }),
                    height: .scaled(0.8) + .if(between: 0...50, modifier: { $0 * 0.5 })
                ),
                constraints: [
                    topLayoutGuideConstraint,
                    tableView.contentLayoutConstraint(for: [.top(.pull(from: .outer))])
                ]
            ),
            bottomView.layoutBlock( // red
                with: Layout(x: .center(), y: .bottom(), width: .fixed(100), height: .fixed(50)),
                constraints: [
                    view.layoutConstraint(for: [.bottom(.limit(on: .inner))]),
                    layoutGuide.layoutConstraint(for: [.bottom(.limit(on: .inner))])
                ]
            ),
            bottomView2.layoutBlock( // yellow
                with: Layout(x: .center(), y: .top(), width: .fixed(50), height: .fixed(50)),
                constraints: [
                    layoutGuide.layoutConstraint(for: [.bottom(.limit(on: .inner))]),
                    tableView.contentLayoutConstraint(for: [.bottom(.align(by: .outer))])
                ]
            ),
            bottomView3.layoutBlock( // green
                with: Layout(x: .center(), y: .top(between: 0...10), width: .fixed(50), height: .between(30...70)),
                constraints: [
                    bottomView2.layoutConstraint(for: [.bottom(.align(by: .outer))]),
                    view.layoutConstraint(for: [.bottom(.limit(on: .inner))])
                ]
            )
        ])
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return strings.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? TextCell else { return }

        cell.label.text = strings[indexPath.row]
        if #available(iOS 10.0, *) {
            blocks[indexPath.row].apply(for: cell.label)
        } else {
            // Fallback on earlier versions
        }
//        Layout.equal.apply(for: cell.label, use: [(cell.bounds, LayoutAnchor.insets(UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)))])
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        let stringConstraint = strings[indexPath.row].layoutConstraint(attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14)])
//        let expandedRect = CGRect(origin: .zero, size: CGSize(width: tableView.frame.width - 40, height: CGFloat.greatestFiniteMagnitude))
//
//        return stringConstraint.constrained(sourceRect: .zero, by: expandedRect).height.rounded(.up) + 20
        if #available(iOS 10.0, *) {
            return blocks[indexPath.row].contentRect(fitting: CGRect(origin: .zero, size: CGSize(width: tableView.frame.width, height: CGFloat.greatestFiniteMagnitude))).height.rounded(.up)
        } else {
            return 100
        }
    }
}
