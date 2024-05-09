import Foundation
import CxxStdlib
import OBSModule

public final class ColorSource {
  var sourceInfo: obs_source_info
  let identifier = "hello"

  public init() {
    sourceInfo = obs_source_info()
    sourceInfo.id = identifier.withCString { $0 }
    sourceInfo.id = ("hello" as NSString).utf8String
  }

  func register() {
    withUnsafePointer(to: &sourceInfo) {
      obs_register_source_s($0, MemoryLayout<obs_source_info>.size)
    }
  }
}

public final class ObjectManager: @unchecked Sendable {
  public static let shared = ObjectManager()
  public static func Singleton() -> ObjectManager {
    return shared
  }

  public var colorSource: ColorSource?

  private init() {}

  public func load() {
    colorSource = ColorSource()
  }

  public func unload() {
    colorSource = nil
  }

  public func sourceRegister() {
    colorSource?.register()
  }
}
