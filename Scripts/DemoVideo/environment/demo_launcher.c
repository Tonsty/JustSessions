// The demo app's main executable: sets the isolated environment, then runs the real app binary beside it.
// build_demo_app.sh generates demo_launcher_environment.h from settings.sh, so no path is written here.
#include <limits.h>
#include <mach-o/dyld.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "demo_launcher_environment.h"

int main(int argc, char **argv) {
  for (const char **assignment = demo_environment; *assignment; assignment++) {
    putenv(strdup(*assignment));
  }
  char path[PATH_MAX];
  uint32_t size = sizeof(path);
  if (_NSGetExecutablePath(path, &size) != 0) return 1;
  char *name = strrchr(path, '/');
  if (!name) return 1;
  strcpy(name + 1, "JustSessionsReal");
  argv[0] = path;
  execv(path, argv);
  return 1;
}
