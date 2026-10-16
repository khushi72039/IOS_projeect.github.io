import SwiftUI

enum ImageHelper {
    
    // Image ko chhota (150x150) aur heavily compressed karke Base64 string banata hai
    static func compressToBase64(_ image: UIImage) -> String? {
        let targetSize = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        guard let data = resizedImage.jpegData(compressionQuality: 0.4) else { return nil }
        return data.base64EncodedString()
    }
    
    // Base64 string se wapas UIImage banata hai
    static func imageFromBase64(_ base64String: String) -> UIImage? {
        guard let data = Data(base64Encoded: base64String) else { return nil }
        return UIImage(data: data)
    }
}
