import Foundation

final class AnyBox: @unchecked Sendable, Hashable {
    static func == (lhs: AnyBox, rhs: AnyBox) -> Bool {
      return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

  fileprivate var box: Any?

  init(_ value: Any) {
    box = value
  }

  func get<T>() -> T? {
    return box as? T
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }
}


public final class ObjectManager: @unchecked Sendable {
  public static let shared = ObjectManager()
  public static func singleton() -> ObjectManager {
    return shared
  }

  private var stored: Set<AnyBox> = []
  private var lock = NSRecursiveLock()

  private init() {}

  deinit {
    stored.removeAll()
  }

  public func load() {
  }

  public func unload() {
  }

  internal func createSource<T>(_ source: T) -> UnsafeMutableRawPointer {
    return lock.withLock {
      let anyBox = AnyBox(source)
      stored.insert(anyBox)
      return UnsafeMutableRawPointer(Unmanaged.passUnretained(anyBox).toOpaque())
    }
  }

  internal func destroySource(_ ptr: UnsafeMutableRawPointer) {
    lock.withLock {
      let anyBox = Unmanaged<AnyBox>.fromOpaque(ptr).takeUnretainedValue()
      _ = stored.remove(anyBox)
    }
  }

  internal func isExists(_ ptr: UnsafeMutableRawPointer) -> Bool {
    return lock.withLock {
      let anyBox = Unmanaged<AnyBox>.fromOpaque(ptr).takeUnretainedValue()
      return stored.contains(anyBox)
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
  precondition(ObjectManager.shared.isExists(ptr), "withUnsafeBound: pointer is not managed by ObjectManager")
  let anyBox = Unmanaged<AnyBox>.fromOpaque(ptr).takeUnretainedValue()
  guard let containedValue: T = anyBox.get() else {
    fatalError("withUnsafeBound: failed to cast to \(T.self)")
  }
  var value = containedValue
  let result = mutate(&value)
  anyBox.box = value
  return result
}
