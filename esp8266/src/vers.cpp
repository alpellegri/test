#define VERSION "0.2.0.4"

static const char *build_str = VERSION " | " __DATE__ " " __TIME__;

const char *VERS_getVersion(void) { return build_str; }
