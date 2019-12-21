//
//  CommonExtension.swift
//  Contacts
//
//  Created by Uzair Dhada on 20/10/19.
//  Copyright © 2019 Go Jek. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func setGradient(colors: [CGColor], angle: Float = 0) {
            
            if let lastLayer = self.layer.sublayers?.first(where: { (layer) -> Bool in
                return layer.name ?? "" == "Gradient"
            }) {
                
                lastLayer.removeFromSuperlayer()
            }
            let gradient: CAGradientLayer = CAGradientLayer()
            gradient.name = "Gradient"
            gradient.frame = bounds
            gradient.colors = colors
            
            let alpha: Float = angle / 360
            let startPointX = powf(
                sinf(2 * Float.pi * ((alpha + 0.75) / 2)),
                2
            )
            let startPointY = powf(
                sinf(2 * Float.pi * ((alpha + 0) / 2)),
                2
            )
            let endPointX = powf(
                sinf(2 * Float.pi * ((alpha + 0.25) / 2)),
                2
            )
            let endPointY = powf(
                sinf(2 * Float.pi * ((alpha + 0.5) / 2)),
                2
            )
            
            gradient.endPoint = CGPoint(x: CGFloat(endPointX),y: CGFloat(endPointY))
            gradient.startPoint = CGPoint(x: CGFloat(startPointX), y: CGFloat(startPointY))
            layer.insertSublayer(gradient, at: 0)
        }
    
    func activityStartAnimating() {
        let backgroundView = UIView()
        backgroundView.frame = CGRect.init(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)
        backgroundView.backgroundColor = UIColor.clear
        backgroundView.tag = 123

        var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
        activityIndicator = UIActivityIndicatorView(frame: CGRect.init(x: 0, y: 0, width: 50, height: 50))
        activityIndicator.center = self.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = UIActivityIndicatorView.Style.medium
        activityIndicator.color = UIColor.lightGray
        activityIndicator.startAnimating()
        self.isUserInteractionEnabled = false

        backgroundView.addSubview(activityIndicator)

        self.addSubview(backgroundView)
    }

    func activityStopAnimating() {
        if let background = viewWithTag(123){
            background.removeFromSuperview()
        }
        self.isUserInteractionEnabled = true
    }
}

extension UIImageView {
    func loadImageFrom(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
    
    func setborderWithWidth(width : CGFloat) {
        self.layer.borderWidth = width
    }
    
    func setBorderColor(color : CGColor) {
        self.layer.borderColor = color
    }
    
}

extension String {
    var isPhoneNumber: Bool {
        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.phoneNumber.rawValue)
            let matches = detector.matches(in: self, options: [], range: NSRange(location: 0, length: self.count))
            if let res = matches.first {
                return res.resultType == .phoneNumber && res.range.location == 0 && res.range.length == self.count
            } else {
                return false
            }
        } catch {
            return false
        }
    }
    
    var isValidEmail: Bool {
        // here, `try!` will always succeed because the pattern is valid
        let regex = try! NSRegularExpression(pattern: "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$", options: .caseInsensitive)
        return regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: count)) != nil
    }
}
    
extension UIViewController {
    
    func alert(message: String, title: String ) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
}

extension Date {
    func stringFromDate(date : Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateFormatter.string(from: date)
    }
}

extension Dictionary {
    func percentEscaped() -> String {
        return map { (key, value) in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="

        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}
