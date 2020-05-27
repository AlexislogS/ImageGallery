//
//  ImageGalleryCollectionViewController.swift
//  ImageGallery
//
//  Created by Alex Yatsenko on 13.05.2020.
//  Copyright © 2020 Alexislog's Production. All rights reserved.
//

import UIKit

final class ImageGalleryCollectionViewController: UICollectionViewController {
    
    private let itemsPerRow: CGFloat = 3
    private let sectionInsets = UIEdgeInsets(top: 20,
                                             left: 20,
                                             bottom: 20,
                                             right: 20)
    private var scale: CGFloat = 1  {
        didSet { collectionView?.collectionViewLayout.invalidateLayout() }
    }
    
    var document: ImageGalleryDocument?
    var imageGallery = ImageGallery() {
        didSet {
            collectionView?.reloadData()
        }
    }
    
    private var firstImage: UIImage? {
        return (collectionView?.cellForItem(at: IndexPath(row: 0, section: 0)) as? ImageCollectionViewCell)?.imageGalleryView.image
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.dropDelegate = self
        collectionView?.dragDelegate = self
        collectionView?.dragInteractionEnabled = true
        collectionView?.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(zoom(_:))))
        createGarbageView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        document?.open(completionHandler: { success in
            if success {
                self.title = self.document?.localizedName
                self.imageGallery = self.document?.imageGallery ?? ImageGallery()
                self.imageGallery.images.mutateEach { image in
                    image.url.changeLocalURL()
                }
                self.collectionView?.reloadData()
            }
        })
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "ShowImage" else { return }
        if let imageVC = segue.destination as? ImageViewController,
            let cell = sender as? ImageCollectionViewCell,
            let indexPath = collectionView?.indexPath(for: cell) {
            imageVC.imageURL = imageGallery.images[indexPath.item].url
        }
    }

    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageGallery.images.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath)
        
        if let imageCell = cell as? ImageCollectionViewCell {
            imageCell.changeAspectRatio = { [weak self] in
                if let aspectRatio = self?.imageGallery.images[indexPath.item].aspectRatio, aspectRatio < 0.95 || aspectRatio > 1.05 {
                    self?.imageGallery.images[indexPath.item].aspectRatio = 1
                    self?.collectionView?.collectionViewLayout.invalidateLayout()
                }
            }
            imageCell.imageURL = imageGallery.images[indexPath.item].url
        }
        
        return cell
    }
    
    private func createGarbageView() {
        guard let navBarBounds = navigationController?.navigationBar.bounds else { return }
        let garbageView = GarbageView(
            frame: CGRect(x: navBarBounds.width * 0.6,
                          y: 0,
                          width: navBarBounds.width * 0.4,
                          height: navBarBounds.height)
        )
        garbageView.garbageViewDidChanged = { [weak self] in
            self?.documentChanged()
        }
        let barButton = UIBarButtonItem(customView: garbageView)
        navigationItem.rightBarButtonItem = barButton
    }
    
    private func documentChanged() {
        document?.imageGallery = imageGallery
        if document?.imageGallery != nil {
            document?.updateChangeCount(.done)
        }
    }
    
    @IBAction func close(_ sender: UIBarButtonItem) {
        if let firstImage = firstImage {
            document?.thumbnail = firstImage
        }
        dismiss(animated: true) {
            self.document?.close()
        }
    }
    
    @objc private func zoom(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .changed:
            scale *= gesture.scale
            gesture.scale = 1
        default: break
        }
    }
}

    // MARK: - UICollectionViewDelegateFlowLayout

extension ImageGalleryCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let aspectRatio = CGFloat(imageGallery.images[indexPath.item].aspectRatio)
        let gapWidth = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = collectionView.bounds.width - gapWidth
        let widthPerItem = (availableWidth / itemsPerRow) * scale
        return CGSize(width: widthPerItem, height: widthPerItem / aspectRatio)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.bottom
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.right / 2
    }
}

// MARK: - UICollectionViewDragDelegate

extension ImageGalleryCollectionViewController: UICollectionViewDragDelegate {
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = collectionView
        return dragItems(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return dragItems(at: indexPath)
    }
    
    private func dragItems(at indexPath: IndexPath) -> [UIDragItem] {
        guard let cell = collectionView.cellForItem(at: indexPath) as? ImageCollectionViewCell, let image = cell.imageGalleryView.image else { return [] }
        let dragItem = UIDragItem(itemProvider: NSItemProvider(object: image))
        dragItem.localObject = indexPath
        return [dragItem]
    }
    
}

// MARK: - UICollectionViewDropDelegate

extension ImageGalleryCollectionViewController: UICollectionViewDropDelegate {
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView
        return isSelf ? session.canLoadObjects(ofClass: UIImage.self) : session.canLoadObjects(ofClass: UIImage.self) && session.canLoadObjects(ofClass: NSURL.self)
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView
        return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent: .insertAtDestinationIndexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
        for item in coordinator.items {
            if let sourceIndexPath = item.sourceIndexPath {
                collectionView.performBatchUpdates( {
                    let image = imageGallery.images.remove(at: sourceIndexPath.item)
                    collectionView.deleteItems(at: [sourceIndexPath])
                    imageGallery.images.insert(image, at: destinationIndexPath.item)
                    collectionView.insertItems(at: [destinationIndexPath])
                })
                coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                documentChanged()
            } else {
                let placeholderContext = coordinator.drop(
                    item.dragItem,
                    to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath, reuseIdentifier: "DropPlaceholderCell")
                )
                var imageURL: URL?
                var aspectRatio: Double?
                item.dragItem.itemProvider.loadObject(ofClass: NSURL.self) { (provider, error) in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                    DispatchQueue.main.async {
                        if let url = provider as? URL {
                            imageURL = url.imageURL
                        }
                    }
                }
                item.dragItem.itemProvider.loadObject(ofClass: UIImage.self) { (provider, error) in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                    DispatchQueue.main.async {
                        if let image = provider as? UIImage {
                            aspectRatio = Double(image.size.width / image.size.height)
                            if imageURL != nil, aspectRatio != nil {
                                image.check(imageURL!) { url in
                                    if let urlChecked = url {
                                        imageURL = urlChecked
                                        if placeholderContext.commitInsertion(dataSourceUpdates: { insertionIndexPath in
                                            self.imageGallery.images.insert(Image(url: imageURL!, aspectRatio: aspectRatio!), at: insertionIndexPath.item)
                                        }) {
                                            self.documentChanged()
                                            print("Fine")
                                        } else {
                                            placeholderContext.deletePlaceholder()
                                            print("Bad")
                                        }
                                    } else {
                                        placeholderContext.deletePlaceholder()
                                        print("Awful")
                                    }
                                }
                            } else {
                                placeholderContext.deletePlaceholder()
                            }
                        }
                    }
                }
            }
        }
    }
    
}
