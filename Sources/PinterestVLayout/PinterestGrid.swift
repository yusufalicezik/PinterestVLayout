//
//  PinterestGrid.swift
//  PinterestVLayout
//
//  Created by Yusuf on 17.01.2026.
//

import SwiftUI

// MARK: - Constants
private enum PinterestGridConstants {
    static let cellIdentifier = "PinterestGridCell"
    static let headerIdentifier = "PinterestGridHeader"
}

// MARK: - PinterestGrid
public struct PinterestGrid<Data: Identifiable & Equatable, Content: View, Header: View>: UIViewRepresentable {
    let sections: [PinterestGridSection<Data>]
    let columns: Int
    let spacing: CGFloat
    let isLoading: Bool
    let onLoadMore: () -> Void
    let content: (Data) -> Content
    let header: ((PinterestGridSection<Data>) -> Header)?

    // --- INIT 1: Multi-Section Header ---
    public init(
        sections: [PinterestGridSection<Data>],
        columns: Int = 2,
        spacing: CGFloat = 10,
        isLoading: Bool = false,
        onLoadMore: @escaping () -> Void = {},
        @ViewBuilder content: @escaping (Data) -> Content,
        @ViewBuilder header: @escaping (PinterestGridSection<Data>) -> Header
    ) {
        self.sections = sections
        self.columns = columns
        self.spacing = spacing
        self.isLoading = isLoading
        self.onLoadMore = onLoadMore
        self.content = content
        self.header = header
    }

    // --- INIT 2: Single-Section / Without Header ---
    public init(
        data: [Data],
        columns: Int = 2,
        spacing: CGFloat = 10,
        isLoading: Bool = false,
        onLoadMore: @escaping () -> Void = {},
        @ViewBuilder content: @escaping (Data) -> Content
    ) where Header == EmptyView {
        self.sections = [PinterestGridSection(id: "default", items: data)]
        self.columns = columns
        self.spacing = spacing
        self.isLoading = isLoading
        self.onLoadMore = onLoadMore
        self.content = content
        self.header = nil
    }

    public func makeUIView(context: Context) -> UICollectionView {
        let layout = PinterestVLayout()
        layout.numberOfColumns = columns
        layout.cellPadding = spacing / 2
        layout.delegate = context.coordinator
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        
        // Register Cell & Header
        cv.register(UICollectionViewCell.self, forCellWithReuseIdentifier: PinterestGridConstants.cellIdentifier)
        cv.register(PinterestHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: PinterestGridConstants.headerIdentifier)
        
        cv.dataSource = context.coordinator
        cv.delegate = context.coordinator
        cv.showsVerticalScrollIndicator = false
        return cv
    }

    public func updateUIView(_ uiView: UICollectionView, context: Context) {
        context.coordinator.parent = self
        if let layout = uiView.collectionViewLayout as? PinterestVLayout {
            layout.clearCache()
        }
        uiView.reloadData()
    }

    public func makeCoordinator() -> Coordinator { Coordinator(self) }

    public class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDelegate, @MainActor PinterestVLayoutDelegate {
        var parent: PinterestGrid
        private var heightCache: [Data.ID: CGFloat] = [:]
        private var headerHeightCache: [Int: CGFloat] = [:]
        private var lastWidth: CGFloat = 0

        init(_ parent: PinterestGrid) { self.parent = parent }

        // --- DataSource ---
        public func numberOfSections(in collectionView: UICollectionView) -> Int {
            parent.sections.count
        }

        public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            parent.sections[section].items.count
        }

        public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PinterestGridConstants.cellIdentifier, for: indexPath)
            cell.contentConfiguration = UIHostingConfiguration {
                parent.content(parent.sections[indexPath.section].items[indexPath.item])
            }
            .margins(.all, 0)
            return cell
        }

        // --- Header ---
        public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: PinterestGridConstants.headerIdentifier, for: indexPath) as! PinterestHeaderView
            
            let section = parent.sections[indexPath.section]
            
            // Eğer section'da contentView varsa direkt onu kullan
            if let contentView = section.contentView {
                headerView.configure(with: contentView)
            } else if let headerClosure = parent.header {
                headerView.configure(with: headerClosure(section))
            }
            return headerView
        }

        // --- Pagination ---
        public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
            let isLastSection = indexPath.section == parent.sections.count - 1
            let isLastItem = indexPath.item >= parent.sections[indexPath.section].items.count - 5
            
            if isLastSection && isLastItem && !parent.isLoading {
                DispatchQueue.main.async { self.parent.onLoadMore() }
            }
        }

        // --- Height Calculation (Delegates) ---
        public func collectionView(_ collectionView: UICollectionView, heightForHeaderInSection section: Int) -> CGFloat {
            if let cached = headerHeightCache[section] { return cached }
            
            let sectionData = parent.sections[section]
            
            let headerView: AnyView
            if let contentView = sectionData.contentView {
                headerView = contentView
            } else if let headerClosure = parent.header {
                headerView = AnyView(headerClosure(sectionData))
            } else {
                return 0
            }
            
            // Header Height Calculation
            let host = UIHostingController(rootView: headerView)
            let size = host.view.sizeThatFits(CGSize(width: collectionView.bounds.width, height: CGFloat.greatestFiniteMagnitude))
            headerHeightCache[section] = size.height
            return size.height
        }

        public func collectionView(_ collectionView: UICollectionView, heightForPhotoAtIndexPath indexPath: IndexPath) -> CGFloat {
            let viewWidth = collectionView.bounds.width > 0 ? collectionView.bounds.width : UIScreen.main.bounds.width
            
            if viewWidth != lastWidth {
                heightCache.removeAll()
                headerHeightCache.removeAll()
                lastWidth = viewWidth
            }

            let item = parent.sections[indexPath.section].items[indexPath.item]
            if let cachedHeight = heightCache[item.id] { return cachedHeight }
            
            // Cell Height Calculcation
            let colWidth = (viewWidth / CGFloat(parent.columns)) - parent.spacing
            let hostView = UIHostingController(rootView: parent.content(item))
            let size = hostView.view.sizeThatFits(CGSize(width: colWidth, height: CGFloat.greatestFiniteMagnitude))
            
            heightCache[item.id] = size.height
            return size.height
        }
    }
}
