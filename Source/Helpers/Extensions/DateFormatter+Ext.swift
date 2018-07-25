//
//  DateFormatter+Ext.swift
//  Telegraph
//
//  Created by Yvo van Beek on 2/10/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import Foundation

extension DateFormatter {
  /// Initializes a new DateFormatter with a custom date format.
  convenience init(dateFormat: String) {
    self.init()
    self.dateFormat = dateFormat
  }

  /// Returns a DateFormatter configured according to the RFC7231 spec.
  public static var rfc7231: DateFormatter {
    let formatter = DateFormatter(dateFormat: "EE, d MMM yyyy HH:mm:ss zzz")
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(abbreviation: "GMT")
    return formatter
  }
}
