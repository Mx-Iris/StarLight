//
//  XiblessHostingController.swift
//  StarLight
//
//  Created by JH on 2025/1/3.
//

import SwiftUI

class XiblessHostingController<Content: View>: NSHostingController<Content> {
    override init(rootView: Content) {
        super.init(rootView: rootView)
    }

    @available(*, unavailable)
    @MainActor @preconcurrency dynamic required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
