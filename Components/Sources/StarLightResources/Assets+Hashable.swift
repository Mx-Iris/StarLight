//
//  Assets+Hashable.swift
//  CodeOrganizerAssets
//
//  Created by JH on 2023/8/2.
//

import AppKit

extension ImageAsset: Hashable {
    public static func == (lhs: ImageAsset, rhs: ImageAsset) -> Bool {
        lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
