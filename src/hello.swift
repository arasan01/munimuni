import Foundation
import CxxStdlib
import MUNIMUNI

public func hello() {
  let value = OBS_ICON_TYPE_AUDIO_INPUT.rawValue
  let logStr = "obs icon audio input value: \(value)"
  let cxxLogStr = std.string(logStr)
  swift_log_obs_print(cxxLogStr)
}
