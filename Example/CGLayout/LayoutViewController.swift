//
//  LayoutViewController.swift
//  CGLayout_Example
//
//  Created by Denis Koryttsev on 21/05/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import CGLayout

final class ContentView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        print(#function + " called")
    }
}

@available(iOS 10.0, *)
class LayoutViewController: UIViewController {
    var contentView: ContentView!
    var layoutManager: LayoutManager<UIView>!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Change frame", style: .plain, target: self, action: #selector(changeFrame))

        contentView = ContentView(frame: view.bounds)
        view.addSubview(contentView)

        let redView = UIView(backgroundColor: .red)
        contentView.addSubview(redView)
        let greenView = UIView(backgroundColor: .green)
        contentView.addSubview(greenView)
        let blueView = UIView(backgroundColor: .blue)
        contentView.addSubview(blueView)

        self.layoutManager = LayoutManager<UIView>(view: contentView, scheme:
            LayoutScheme(blocks: [
                redView.layoutBlock(with: Layout(x: .left(), y: .top(), width: .fixed(200), height: .fixed(150))),
                blueView.layoutBlock(with: Layout(x: .center(), y: .center(), width: .fixed(200), height: .fixed(200))),
                greenView.layoutBlock(with: Layout(x: .left(), y: .bottom(), width: .fixed(150), height: .fixed(200)))
            ])
        )
    }

    @objc func changeFrame() {
        let alert = UIAlertController(title: nil, message: "New frame", preferredStyle: .alert)

        
        alert.addTextField { (tf) in
            tf.text = "\(self.contentView.frame.origin.x)"
        }
        alert.addTextField { (tf) in
            tf.text = "\(self.contentView.frame.origin.y)"
        }
        alert.addTextField { (tf) in
            tf.text = "\(self.contentView.frame.width)"
        }
        alert.addTextField { (tf) in
            tf.text = "\(self.contentView.frame.height)"
        }

        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) in
            self.contentView.frame = CGRect(x: Double(alert.textFields![0].text ?? "0") ?? 0, y: Double(alert.textFields![1].text ?? "0") ?? 0,
                                            width: Double(alert.textFields![2].text ?? "0") ?? 0, height: Double(alert.textFields![3].text ?? "0") ?? 0)
        }))

        present(alert, animated: false, completion: nil)
    }
}
