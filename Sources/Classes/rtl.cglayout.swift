//
//  rtl.cglayout.swift
//  Pods
//
//  Created by Denis Koryttsev on 13/10/2019.
//

import Foundation

public struct Configuration {
    let isRTLMode: Bool = false

    static private(set) var `default` = Configuration()

    static func setDefault(configuration: Configuration) {
        Configuration.default = configuration
    }
}
