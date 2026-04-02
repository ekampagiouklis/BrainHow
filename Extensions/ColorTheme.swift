import SwiftUI

extension Color {
    static var themeDarkBlue: Color {
        UserDefaults.standard.bool(forKey: "highContrastUI") ? .black : Color(red: 12/255, green: 16/255, blue: 28/255)
    }
    static var themeLightBlue: Color {
        UserDefaults.standard.bool(forKey: "highContrastUI") ? Color(red: 100/255, green: 200/255, blue: 255/255) : Color(red: 172/255, green: 186/255, blue: 196/255)
    }
    static var themeBeige: Color {
        UserDefaults.standard.bool(forKey: "highContrastUI") ? .white : Color(red: 225/255, green: 217/255, blue: 188/255)
    }
    static var themeCream: Color {
        UserDefaults.standard.bool(forKey: "highContrastUI") ? .white : Color(red: 240/255, green: 240/255, blue: 219/255)
    }
}

extension UIColor {
    static var themeDarkBlue: UIColor {
        UserDefaults.standard.bool(forKey: "highContrastUI") ? .black : UIColor(red: 12/255, green: 16/255, blue: 28/255, alpha: 1.0)
    }
    static var themeLightBlue: UIColor {
        UserDefaults.standard.bool(forKey: "highContrastUI") ? UIColor(red: 100/255, green: 200/255, blue: 255/255, alpha: 1.0) : UIColor(red: 172/255, green: 186/255, blue: 196/255, alpha: 1.0)
    }
    static var themeBeige: UIColor {
        UserDefaults.standard.bool(forKey: "highContrastUI") ? .white : UIColor(red: 225/255, green: 217/255, blue: 188/255, alpha: 1.0)
    }
    static var themeCream: UIColor {
        UserDefaults.standard.bool(forKey: "highContrastUI") ? .white : UIColor(red: 240/255, green: 240/255, blue: 219/255, alpha: 1.0)
    }
}
