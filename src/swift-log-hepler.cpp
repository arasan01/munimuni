#include <string>
#include <obs-module.h>
#include <plugin-support.h>

void swift_log_obs_print(const std::string &message) {
  obs_log(LOG_INFO, "from Swift: %s\n",message.c_str());
}
