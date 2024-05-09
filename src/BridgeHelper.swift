import Foundation
import CxxStdlib
import OBSModule

internal enum LogLevel {
  case DEBUG
  case INFO
  case WARNING
  case ERROR

  var obsLogLevel: Int {
    switch self {
    case .DEBUG:
      return LOG_DEBUG
    case .INFO:
      return LOG_INFO
    case .WARNING:
      return LOG_WARNING
    case .ERROR:
      return LOG_ERROR
    }
  }
}

func printOBS(_ level: LogLevel = .INFO, _ text: String) {
  swift_log_obs_print(Int32(level.obsLogLevel), std.string(text))
}
