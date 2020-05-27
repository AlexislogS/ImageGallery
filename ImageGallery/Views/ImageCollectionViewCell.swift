//
//  ImageCollectionViewCell.swift
//  ImageGallery
//
//  Created by Alex Yatsenko on 13.05.2020.
//  Copyright © 2020 Alexislog's Production. All rights reserved.
//

import UIKit

final class ImageCollectionViewCell: UICollectionViewCell {
    
    private var cache = URLCache.shared
    
    var imageURL: URL? { didSet { updateUI() } }
    
    var changeAspectRatio: (() -> Void)?
    
    @IBOutlet private(set) weak var imageGalleryView: UIImageView!
    @IBOutlet private weak var spinner: UIActivityIndicatorView!
    
    private func updateUI() {
        guard let url = imageURL else { return }
        imageGalleryView.image = nil
        let request = URLRequest(url: url)
        spinner?.startAnimating()
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let data = self.cache.cachedResponse(for: request)?.data,
                let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.imageGalleryView.transition(to: image)
                    self.spinner?.stopAnimating()
                }
            } else {
                URLSession.shared.dataTask(with: request) { (data, response, error) in
                    if let data = data,
                        let response = response,
                        (response as? HTTPURLResponse)?.statusCode == 200,
                        let image = UIImage(data: data),
                        url == self.imageURL {
                        let cachedData = CachedURLResponse(response: response, data: data)
                        self.cache.storeCachedResponse(cachedData, for: request)
                        DispatchQueue.main.async {
                            self.imageGalleryView.image = image
                            self.spinner.stopAnimating()
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.spinner?.stopAnimating()
                            self.imageGalleryView.image = "Error 😔".emojiToImage()?.applyBlurEffect()
                            self.changeAspectRatio?()
                        }
                    }
                }.resume()
            }
        }
        spinner?.stopAnimating()
    }
}
