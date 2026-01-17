import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Layout Delegate & Engine
public protocol PinterestVLayoutDelegate: AnyObject {
    func collectionView(_ collectionView: UICollectionView, heightForPhotoAtIndexPath indexPath: IndexPath) -> CGFloat
    func collectionView(_ collectionView: UICollectionView, heightForHeaderInSection section: Int) -> CGFloat
}

public final class PinterestVLayout: UICollectionViewLayout {
    public weak var delegate: PinterestVLayoutDelegate?
    public var numberOfColumns = 2
    public var cellPadding: CGFloat = 6
    
    private var cache: [UICollectionViewLayoutAttributes] = []
    private var contentHeight: CGFloat = 0
    private var contentWidth: CGFloat {
        guard let collectionView = collectionView else { return 0 }
        return collectionView.bounds.width
    }

    public override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }

    public override func prepare() {
        guard cache.isEmpty, let collectionView = collectionView else { return }
        
        let columnWidth = contentWidth / CGFloat(numberOfColumns)
        var yOffset: [CGFloat] = .init(repeating: 0, count: numberOfColumns)
        
        for section in 0..<collectionView.numberOfSections {
            let headerHeight = delegate?.collectionView(collectionView, heightForHeaderInSection: section) ?? 0
            if headerHeight > 0 {
                let maxY = yOffset.max() ?? 0
                let attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, with: IndexPath(item: 0, section: section))
                attributes.frame = CGRect(x: 0, y: maxY, width: contentWidth, height: headerHeight)
                cache.append(attributes)
                
                yOffset = yOffset.map { _ in maxY + headerHeight }
            }
            
            let xOffset: [CGFloat] = (0..<numberOfColumns).map { CGFloat($0) * columnWidth }
            
            for item in 0..<collectionView.numberOfItems(inSection: section) {
                let indexPath = IndexPath(item: item, section: section)
                
                let photoHeight = delegate?.collectionView(collectionView, heightForPhotoAtIndexPath: indexPath) ?? 100
                let height = (cellPadding * 2) + photoHeight
                
                let column = yOffset.firstIndex(of: yOffset.min() ?? 0) ?? 0
                let frame = CGRect(x: xOffset[column], y: yOffset[column], width: columnWidth, height: height)
                let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)
                
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = insetFrame
                cache.append(attributes)
                
                contentHeight = max(contentHeight, frame.maxY)
                yOffset[column] = yOffset[column] + height
            }
        }
    }

    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return cache.filter { $0.frame.intersects(rect) }
    }
    
    public func clearCache() {
        cache.removeAll()
        contentHeight = 0
    }
}
