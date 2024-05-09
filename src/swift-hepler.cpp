#include <string>
#include <obs-module.h>
#include <plugin-support.h>

void swift_log_obs_print(const int log_level, const std::string &message) {
  obs_log(log_level, "%s\n",message.c_str());
}
