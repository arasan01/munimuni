import Foundation

public final class ObjectManager: @unchecked Sendable {
  public static let shared = ObjectManager()
  public static func singleton() -> ObjectManager {
    return shared
  }

  private var stored: Set<UnsafeMutableRawPointer> = []
  private var lock = NSRecursiveLock()

  private init() {}

  deinit {
    stored.forEach { $0.deallocate() }
  }

  public func load() {
  }

  public func unload() {
  }

  internal func createSource<T>(_ source: T) -> UnsafeMutableRawPointer {
    return lock.withLock {
      let allocatePtr = UnsafeMutablePointer<T>.allocate(capacity: 1)
      allocatePtr.initialize(to: source)
      printOBS(.INFO, allocatePtr.debugDescription)
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

  internal func isExists(_ ptr: UnsafeMutableRawPointer) -> Bool {
    return lock.withLock {
      return stored.contains(ptr)
    }
  }

  public func sourcePresetsRegister() {
    ColorSourcePresets.register()
  }
}

@discardableResult
internal func withUnsafeBound<T, V>(
  to type: T.Type = T.self,
  ptr: UnsafeMutableRawPointer,
  _ mutate: (inout T) -> V
) -> V {
  #if DEBUG
  precondition(ObjectManager.shared.isExists(ptr), "withUnsafeBound: pointer is not managed by ObjectManager")
  #endif
  let boundPtr = ptr.assumingMemoryBound(to: type)
  return mutate(&boundPtr.pointee)
}
