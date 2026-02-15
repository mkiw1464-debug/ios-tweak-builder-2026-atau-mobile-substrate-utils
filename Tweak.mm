#include <substrate.h>
#include <dlfcn.h>

%ctor {
    @autoreleasepool {
        ptrace(PT_DENY_ATTACH, 0, 0, 0);
        // Test hook simple
    }
}
