import Foundation

public final class ObjectManager: @unchecked Sendable {
  public static let shared = ObjectManager()
  public static func singleton() -> ObjectManager {
    return shared
  }

  public var colorSourcePresets: ColorSourcePresets?
  private var stored: Set<UnsafeMutableRawPointer> = []
  private var lock = NSRecursiveLock()

  private init() {}

  deinit {
    stored.forEach { $0.deallocate() }
  }

  public func load() {
    colorSourcePresets = ColorSourcePresets()
  }

  public func unload() {
    colorSourcePresets = nil
  }

  internal func createSource<T>(_ source: T) -> UnsafeMutableRawPointer {
    return lock.withLock {
      let allocatePtr = UnsafeMutablePointer<T>.allocate(capacity: 1)
      allocatePtr.initialize(to: source)
      let rawPtr = UnsafeMutableRawPointer(allocatePtr)
      stored.insert(rawPtr)
      return rawPtr
    }
  }

  internal func destroySource(_ ptr: UnsafeMutableRawPointer) {
    lock.withLock {
      if let exists = stored.remove(ptr) {
        exists.deallocate()
      }
    }
  }

  public func sourcePresetsRegister() {
    colorSourcePresets?.register()
  }
}

@discardableResult
internal func withUnsafeBound<T, V>(
  to type: T.Type = T.self,
  ptr: UnsafeMutableRawPointer,
  _ mutate: (inout T) -> V
) -> V {
    let boundPtr = ptr.assumingMemoryBound(to: type)
    return mutate(&boundPtr.pointee)
  }
