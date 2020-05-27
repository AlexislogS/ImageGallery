//
//  ImageViewController.swift
//  ImageGallery
//
//  Created by Alex Yatsenko on 13.05.2020.
//  Copyright © 2020 Alexislog's Production. All rights reserved.
//

import UIKit

final class ImageViewController: UIViewController, UIScrollViewDelegate {
    
    private var imageView = UIImageView()
    private var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
            imageView.sizeToFit()
            scrollView?.contentSize = imageView.frame.size
            spinner?.stopAnimating()
        }
    }
    
    var imageURL: URL? {
        didSet {
            image = nil
            if view.window != nil {
                fetchImage()
            }
        }
    }

    @IBOutlet private weak var scrollView: UIScrollView! {
        didSet {
            scrollView.delegate = self
            scrollView.minimumZoomScale = 1/25
            scrollView.maximumZoomScale = 1
            scrollView.addSubview(imageView)
        }
    }
    @IBOutlet private weak var spinner: UIActivityIndicatorView!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if imageView.image == nil {
            fetchImage()
        }
    }
    
    private func fetchImage() {
        guard let url = imageURL else { return }
        spinner.startAnimating()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if let imageData = try? Data(contentsOf: url) {
                DispatchQueue.main.async {
                    if url == self?.imageURL {
                        self?.image = UIImage(data: imageData)
                    }
                }
            }
        }
    }
    
    // MARK: - UIScrollViewDelegate
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
}
