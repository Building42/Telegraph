//
//  DateFormatter+Ext.swift
//  Telegraph
//
//  Created by Yvo van Beek on 2/10/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

extension DateFormatter {
  convenience init(dateFormat: String) {
    self.init()
    self.locale = Locale(identifier: "en_US_POSIX")
    self.dateFormat = dateFormat
  }
}
