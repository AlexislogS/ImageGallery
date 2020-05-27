//
//  Utilities.swift
//  ImageGallery
//
//  Created by Alex Yatsenko on 15.05.2020.
//  Copyright © 2020 Alexislog's Production. All rights reserved.
//

import UIKit

extension Array {
    
    mutating func mutateEach(_ body: (inout Element) -> ()) {
        for index in self.indices {
            body (&self[index])
        }
    }
}

extension UIViewController {
    var contents: UIViewController {
        if let navCon = self as? UINavigationController {
            return navCon.visibleViewController ?? navCon
        } else {
            return self
        }
    }
}

extension String {
    
    func madeUnique(withRespectTo otherStrings: [String]) -> String {
        var possiblyUnique = self
        var uniqueNumber = 1
        while otherStrings.contains(possiblyUnique) {
            possiblyUnique = self + " \(uniqueNumber)"
            uniqueNumber += 1
        }
        return possiblyUnique
    }
    
    func emojiToImage() -> UIImage? {
        let size = CGSize(width: 160 , height: 160)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        #colorLiteral(red: 0.7368795971, green: 0.9366820587, blue: 0.9764705896, alpha: 0.7592037671).set()
        let rect = CGRect(origin: CGPoint(), size: size)
        UIRectFill(CGRect(origin: CGPoint(), size: size))
        (self as NSString).draw(in: rect,
                                withAttributes: [.font: UIFont.systemFont(ofSize: 30)])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

extension URL {
    
    var imageURL: URL {
        if let url = UIImage.urlToStoreLocallyAsJPEG(named: self.path) {
            return url
        } else {
            for query in query?.components(separatedBy: "&") ?? [] {
                let queryComponents = query.components(separatedBy: "=")
                if queryComponents.count == 2 {
                    if queryComponents[0] == "imgurl", let url = URL(string: queryComponents[1].removingPercentEncoding ?? "") {
                        return url
                    }
                }
            }
            return self.baseURL ?? self
        }
    }
    
    mutating func changeLocalURL() {
        guard self.absoluteString.hasPrefix("file") else {return}
        let urlString = self.absoluteString
        var name = ""
        let pathComponents = urlString.components(separatedBy: "/")
        if pathComponents.count > 1 {
            if pathComponents[pathComponents.count-2] ==
                                      UIImage.localImagesDirectory {
                name = pathComponents.last!
            } else {
                return
            }
        }
        if var url = FileManager.default.urls(for: .applicationSupportDirectory,
                                               in: .userDomainMask).first {
            url = url.appendingPathComponent(UIImage.localImagesDirectory)
            do {
                try FileManager.default.createDirectory(at: url,
                               withIntermediateDirectories: true)
                url = url.appendingPathComponent(name)
                if url.pathExtension != "jpg" {
                    url = url.appendingPathExtension("jpg")
                }
                print ("-----------Change file \n \(self) \n на \n \(url)")
                self = url
            } catch let error {
                print("UIImage.urlToStoreLocallyAsJPEG \(error)")
            }
        }
    }
}

extension UIImageView {
    
    func transition(to image: UIImage?) {
        UIView.transition(with: self,
                          duration: 0.3,
                          options: .transitionCrossDissolve,
                          animations: {
                            self.image = image
        })
    }
}

extension UIImage {
    
    static let localImagesDirectory = "UIImage.storeLocallyAsJPEG"
    
    static func urlToStoreLocallyAsJPEG(named: String) -> URL? {
        var name = named
        let pathComponents = named.components(separatedBy: "/")
        if pathComponents.count > 1 {
            if pathComponents[pathComponents.count-2] == localImagesDirectory {
                name = pathComponents.last!
            } else {
                return nil
            }
        }
        if var url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            url = url.appendingPathComponent(localImagesDirectory)
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                url = url.appendingPathComponent(name)
                if url.pathExtension != "jpg" {
                    url = url.appendingPathExtension("jpg")
                }
                return url
            } catch let error {
                print("UIImage.urlToStoreLocallyAsJPEG \(error)")
            }
        }
        return nil
    }
    
    func storeLocallyAsJPEG(named name: String) -> URL? {
        if let imageData = self.jpegData(compressionQuality: 1.0) {
            if let url = UIImage.urlToStoreLocallyAsJPEG(named: name) {
                do {
                    try imageData.write(to: url)
                    return url
                } catch let error {
                    print("UIImage.storeLocallyAsJPEG \(error)")
                }
            }
        }
        return nil
    }
    
    func check(_ url: URL, handler: @escaping (URL?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let urlContents = try? Data(contentsOf: url.imageURL)
            DispatchQueue.main.async {
                if let data = urlContents,UIImage(data: data) != nil {
                    handler(url)
                } else {
                    if let urlLocal = self.storeLocallyAsJPEG(named:
                          String(Date().timeIntervalSinceReferenceDate)) {
                        print ("Local bad = \(urlLocal) \(self)")
                        handler(urlLocal)
                    } else {
                        handler(nil)
                    }
                }
            }
        }
    }
    
    func applyBlurEffect()-> UIImage {
        let imageToBlur = CIImage(image: self)
        let filter =  CIFilter(name: "CIGaussianBlur")
        filter?.setValue(imageToBlur, forKey: "inputImage")
        filter?.setValue(5, forKey: "inputRadius")
        let resultImage = filter?.value(forKey: "outputImage") as? CIImage
        let blurredImage = UIImage(ciImage: resultImage!)
        
        return blurredImage
    }
}
