import Foundation

extension String {
  var obsString: UnsafePointer<CChar> {
    return self.withCString { $0 }
  }
}

extension StaticString {
  var obsString: UnsafePointer<CChar> {
    return self.withUTF8Buffer { UnsafePointer<CChar>(OpaquePointer($0.baseAddress!)) }
  }
}
