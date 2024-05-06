import Foundation
import CxxStdlib
import MUNIMUNI

public func hello() {
  let value = OBS_ICON_TYPE_AUDIO_INPUT.rawValue
  let logStr = "obs icon audio input value: \(value)"
  let cxxLogStr = std.string(logStr)
  swift_log_obs_print(cxxLogStr)
  var sourceInfo = obs_source_info()
  sourceInfo.id = ("hello" as NSString).utf8String
  let (sourcePointer, sourceSize) = allocateHeapMemoryWithSize(value: sourceInfo)
  obs_register_source_s(sourcePointer, sourceSize)
}

@inline(__always)
func allocateHeapMemory<T>(value: T) -> UnsafePointer<T> {
  let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
  pointer.initialize(to: value)
  return UnsafePointer(pointer)
}

@inline(__always)
func allocateHeapMemoryWithSize<T>(value: T) -> (UnsafePointer<T>, Int) {
  let pointer = allocateHeapMemory(value: value)
  return (pointer, MemoryLayout<T>.size)
}
