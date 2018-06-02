//
//  TableViewController.swift
//  CGLayout
//
//  Created by Denis Koryttsev on 21/09/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import CGLayout

class TextCell: UITableViewCell {
    weak var label: UILabel!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
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
    func apply(for item: LayoutItem) {
        layout.apply(for: item, use: targetConstraints.map { (item.superItem!.bounds, $0) })
    }
}

class TableViewController: UITableViewController {
    let strings = "Lorem Ipsum - это текст-\"рыба\", часто используемый в печати и вэб-дизайне. Lorem Ipsum является стандартной \"рыбой\" для текстов на латинице с начала XVI века. В то время некий безымянный печатник создал большую коллекцию размеров и форм шрифтов, используя Lorem Ipsum для распечатки образцов. Lorem Ipsum не только успешно пережил без заметных изменений пять веков, но и перешагнул в электронный дизайн. Его популяризации в новое время послужили публикация листов Letraset с образцами Lorem Ipsum в 60-х годах и, в более недавнее время, программы электронной вёрстки типа Aldus PageMaker, в шаблонах которых используется Lorem Ipsum".components(separatedBy: ". ")

    let bottomView = UIView()
    let bottomView2 = UIView()
    let layoutGuide = LayoutGuide<UITableView>(frame: UIScreen.main.bounds.insetBy(dx: 0, dy: 100))
    lazy var bottomViewBlock: LayoutBlock<UIView> = self.bottomView.layoutBlock(with: Layout(x: .center(), y: .bottom(), width: .fixed(100), height: .fixed(50)),
                                                                                constraints: [self.layoutGuide.layoutConstraint(for: [LayoutAnchor.Bottom.limit(on: .inner)]),
                                                                                              self.view.layoutConstraint(for: [LayoutAnchor.Bottom.pull(from: .inner)])])
    lazy var bottomView2Block: LayoutBlock<UIView> = self.bottomView2.layoutBlock(with: Layout(x: .center(), y: .top(), width: .fixed(50), height: .fixed(50)),
                                                                                  constraints: [self.layoutGuide.layoutConstraint(for: [LayoutAnchor.Bottom.limit(on: .inner)]),
                                                                                                self.tableView.contentLayoutConstraint(for: [LayoutAnchor.Bottom.align(by: .outer)])])

    lazy var blocks: [ReuseLayoutBlock] = self.strings.map {
        ReuseLayoutBlock(layout: Layout.equal,
                         targetConstraints: [LayoutAnchor.insets(UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20))],
                         contentConstraints: [LayoutAnchor.insets(UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)),
                                              $0.layoutConstraint(attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14)]),
                                              LayoutAnchor.insets(UIEdgeInsets(top: -10, left: 0, bottom: -10, right: 0))])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(TextCell.self, forCellReuseIdentifier: "reuseIdentifier")
        bottomView.backgroundColor = .red
        bottomView2.backgroundColor = .yellow
        tableView.addSubview(bottomView)
        tableView.addSubview(bottomView2)
        tableView.add(layoutGuide: layoutGuide)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bottomViewBlock.layout()
        bottomView2Block.layout()
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
        blocks[indexPath.row].apply(for: cell.label)
//        Layout.equal.apply(for: cell.label, use: [(cell.bounds, LayoutAnchor.insets(UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)))])
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        let stringConstraint = strings[indexPath.row].layoutConstraint(attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14)])
//        let expandedRect = CGRect(origin: .zero, size: CGSize(width: tableView.frame.width - 40, height: CGFloat.greatestFiniteMagnitude))
//
//        return stringConstraint.constrained(sourceRect: .zero, by: expandedRect).height.rounded(.up) + 20
        return blocks[indexPath.row].contentRect(fitting: CGRect(origin: .zero, size: CGSize(width: tableView.frame.width, height: CGFloat.greatestFiniteMagnitude))).height.rounded(.up)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
