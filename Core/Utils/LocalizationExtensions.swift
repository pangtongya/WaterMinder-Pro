//
//  LocalizationExtensions.swift
//  水滴花园 (Bloom)
//
//  Created for internationalization
//

import Foundation

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
    
    func localizedWithArgs(_ arguments: CVarArg...) -> String {
        String(format: self.localized, arguments: arguments)
    }
}
