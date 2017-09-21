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
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        contentView.addSubview(label)
        self.label = label
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class TableViewController: UITableViewController {
    let strings = " Lorem Ipsum - это текст-\"рыба\", часто используемый в печати и вэб-дизайне. Lorem Ipsum является стандартной \"рыбой\" для текстов на латинице с начала XVI века. В то время некий безымянный печатник создал большую коллекцию размеров и форм шрифтов, используя Lorem Ipsum для распечатки образцов. Lorem Ipsum не только успешно пережил без заметных изменений пять веков, но и перешагнул в электронный дизайн. Его популяризации в новое время послужили публикация листов Letraset с образцами Lorem Ipsum в 60-х годах и, в более недавнее время, программы электронной вёрстки типа Aldus PageMaker, в шаблонах которых используется Lorem Ipsum".components(separatedBy: ".")

    let cellLayout: Layout = Layout(x: .left(), y: .top(), width: .scaled(1), height: .scaled(1))

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(TextCell.self, forCellReuseIdentifier: "reuseIdentifier")
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
        cellLayout.apply(for: cell.label)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let stringConstraint = StringLayoutConstraint(string: strings[indexPath.row], attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14)])
        let expandedRect = CGRect(origin: .zero, size: CGSize(width: tableView.frame.width, height: CGFloat.greatestFiniteMagnitude))

        return stringConstraint.constrained(sourceRect: .zero, by: expandedRect).height + 10
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
