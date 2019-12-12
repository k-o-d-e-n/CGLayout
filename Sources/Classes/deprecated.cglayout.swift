//
//  CGLayoutDeprecated.swift
//  CGLayout
//
//  Created by Denis Koryttsev on 07/10/2017.
//

import Foundation

extension LayoutSnapshotProtocol {
    @available(*, deprecated, renamed: "frame")
    public var snapshotFrame: CGRect { return frame }
}
