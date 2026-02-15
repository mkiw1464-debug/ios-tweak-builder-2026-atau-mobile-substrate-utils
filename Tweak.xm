// Tweak.xm - Azurite External test (tanpa ptrace)

#include <substrate.h>
#include <dlfcn.h>

%ctor {
    @autoreleasepool {
        // ptrace(PT_DENY_ATTACH, 0, 0, 0);  // komen dulu untuk test compile

        void* il2cpp = dlopen("libil2cpp.so", RTLD_LAZY);
        if (il2cpp) {
            // Test hook simple
            void* sym = dlsym(il2cpp, "_ZN12PlayerMovement6UpdateEv");
            if (sym) {
                // Placeholder
            }
        }
    }
}
