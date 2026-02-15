// Tweak.xm - Azurite External test

#include <substrate.h>
#include <dlfcn.h>
#include <sys/ptrace.h>

%ctor {
    @autoreleasepool {
        ptrace(PT_DENY_ATTACH, 0, 0, 0);

        void* il2cpp = dlopen("libil2cpp.so", RTLD_LAZY);
        if (il2cpp) {
            // Test hook simple - compile OK kalau sampai sini
            void* sym = dlsym(il2cpp, "_ZN12PlayerMovement6UpdateEv");
            if (sym) {
                // Placeholder
            }
        }
    }
}
