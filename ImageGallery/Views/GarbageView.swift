//
//  GarbageView.swift
//  ImageGallery
//
//  Created by Alex Yatsenko on 19.05.2020.
//  Copyright © 2020 Alexislog's Production. All rights reserved.
//

import UIKit

final class GarbageView: UIView, UIDropInteractionDelegate {
    
    var garbageViewDidChanged: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        let dropInteraction = UIDropInteraction(delegate: self)
        addInteraction(dropInteraction)
        backgroundColor = .clear
        let trashCanImage = UIImage(systemName: "trash")
        let myButton = UIButton(frame: CGRect(x: bounds.width - bounds.height,
                                              y: 0,
                                              width: bounds.height,
                                              height: bounds.height))
        myButton.setImage(trashCanImage, for: .normal)
        addSubview(myButton)
    }
    
    // MARK: - UIDropInteractionDelegate
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: UIImage.self)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return session.localDragSession != nil ? UIDropProposal(operation: .copy) : UIDropProposal(operation: .forbidden)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        session.loadObjects(ofClass: UIImage.self) { providers in
            if let collection = session.localDragSession?.localContext as? UICollectionView,
                let images = (collection.dataSource as? ImageGalleryCollectionViewController)?.imageGallery.images,
                let items = session.localDragSession?.items {
                
                var imageIndexPaths = [IndexPath]()
                var imageIndices = [Int]()
                
                for item in items {
                    if let indexPath = item.localObject as? IndexPath {
                        let index = indexPath.item
                        imageIndexPaths += [indexPath]
                        imageIndices += [index]
                    }
                }
                collection.performBatchUpdates({
                    collection.deleteItems(at: imageIndexPaths)
                    (collection.dataSource as? ImageGalleryCollectionViewController)?.imageGallery.images = images.enumerated().filter { !imageIndices.contains($0.offset) }.map { $0.element }
                })
                self.garbageViewDidChanged?()
            }
        }
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, previewForDropping item: UIDragItem, withDefault defaultPreview: UITargetedDragPreview) -> UITargetedDragPreview? {
        let target = UIDragPreviewTarget(
            container: self,
            center: CGPoint(x: bounds.width - bounds.midY,
                            y: bounds.midY),
            transform: CGAffineTransform(scaleX: 0.1, y: 0.1)
        )
        return defaultPreview.retargetedPreview(with: target)
    }
    
}
