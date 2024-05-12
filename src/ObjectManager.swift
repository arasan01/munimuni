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
      printOBS(.INFO, "access ptr: \(String(describing: rawPtr))")
      return rawPtr
    }
  }

  internal func withUnsafeSource<T, V>(_ type: T.Type = T.self, ptr: UnsafeMutableRawPointer, _ mutate: (inout T) -> V) -> V {
    printOBS(.INFO, "access ptr: \(String(describing: ptr))")
    let typedPtr = ptr.assumingMemoryBound(to: type)
    return lock.withLock {
      var source = typedPtr.pointee
      let v = mutate(&source)
      typedPtr.pointee = source
      return v
    }
  }

  internal func destroySource(_ ptr: UnsafeMutableRawPointer) {
    printOBS(.INFO, "access ptr: \(String(describing: ptr))")
    lock.withLock {
      stored.remove(ptr)
      ptr.deallocate()
    }
  }

  public func sourcePresetsRegister() {
    colorSourcePresets?.register()
  }
}
