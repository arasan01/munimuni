import Foundation

public final class ObjectManager: @unchecked Sendable {
  public static let shared = ObjectManager()
  public static func singleton() -> ObjectManager {
    return shared
  }

  public var colorSourcePresets: ColorSourcePresets?
  private var sources: [ObjectIdentifier: AnyObject] = [:]
  var lock = NSRecursiveLock()

  private init() {}

  public func load() {
    colorSourcePresets = ColorSourcePresets()
  }

  public func unload() {
    colorSourcePresets = nil
  }

  internal func createSource(_ source: AnyObject) -> UnsafeMutableRawPointer? {
    lock.withLock {
      sources[ObjectIdentifier(source)] = source
    }
    return Unmanaged.passUnretained(source).toOpaque()
  }

  internal func destroySource(_ source: AnyObject) {
    lock.withLock {
      _ = sources.removeValue(forKey: ObjectIdentifier(source))
    }
  }

  public func sourcePresetsRegister() {
    colorSourcePresets?.register()
  }
}
