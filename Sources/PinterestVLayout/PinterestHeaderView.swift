//
//  PinterestHeaderView.swift
//  PinterestVLayout
//
//  Created by Yusuf on 17.01.2026.
//

import UIKit
import SwiftUI

final class PinterestHeaderView: UICollectionReusableView {
    private var host: UIHostingController<AnyView>?

    func configure<Content: View>(with content: Content) {
        host?.view.removeFromSuperview()
        
        let hostVC = UIHostingController(rootView: AnyView(content))
        hostVC.view.backgroundColor = .clear
        hostVC.view.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(hostVC.view)
        NSLayoutConstraint.activate([
            hostVC.view.topAnchor.constraint(equalTo: topAnchor),
            hostVC.view.bottomAnchor.constraint(equalTo: bottomAnchor),
            hostVC.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostVC.view.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        self.host = hostVC
    }
}
