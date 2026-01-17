//
//  PinterestGridSection.swift
//  PinterestVLayout
//
//  Created by Yusuf on 17.01.2026.
//

import SwiftUI

public struct PinterestGridSection<Data: Identifiable & Equatable>: Identifiable {
    public let id: AnyHashable
    public let title: String?
    public let contentView: AnyView?
    public let items: [Data]
    
    // Init with title (backward compatible)
    public init(id: AnyHashable = UUID(), title: String? = nil, items: [Data]) {
        self.id = id
        self.title = title
        self.contentView = nil
        self.items = items
    }
    
    // Init with contentView
    public init<V: View>(id: AnyHashable = UUID(), contentView: V, items: [Data]) {
        self.id = id
        self.title = nil
        self.contentView = AnyView(contentView)
        self.items = items
    }
}
