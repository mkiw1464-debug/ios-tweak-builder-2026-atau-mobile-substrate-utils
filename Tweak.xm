// Tweak.xm - Azurite External (kemaskini dengan triple tap 3 jari menu)

#include <substrate.h>
#include <dlfcn.h>
#include <sys/ptrace.h>
#include <UIKit/UIKit.h>

// Config fitur (toggle dari menu nanti)
static BOOL EnableAimbot = NO;
static BOOL StreamProof = NO;

%hook UIWindow
- (void)becomeKeyWindow {
    %orig;

    // Tambah gesture triple tap 3 jari
    UITapGestureRecognizer *tripleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(azuriteTripleTapMenu:)];
    tripleTap.numberOfTapsRequired = 3;
    tripleTap.numberOfTouchesRequired = 3;
    tripleTap.cancelsTouchesInView = NO;  // biar game masih respon touch
    [self addGestureRecognizer:tripleTap];
}

%new
- (void)azuriteTripleTapMenu:(UITapGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        static BOOL menuVisible = NO;
        menuVisible = !menuVisible;

        if (menuVisible) {
            // Menu muncul (test popup dulu - nanti tukar ke ImGui/custom UI)
            UIAlertController *menu = [UIAlertController alertControllerWithTitle:@"Azurite External" message:@"Menu Opened\nToggle fitur di sini nanti" preferredStyle:UIAlertControllerStyleAlert];

            // Toggle Aimbot
            [menu addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Aimbot: %@", EnableAimbot ? @"ON" : @"OFF"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                EnableAimbot = !EnableAimbot;
                // Tambah logic aimbot di sini nanti
            }]];

            // Toggle Stream-Proof
            [menu addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Hide Rec: %@", StreamProof ? @"ON" : @"OFF"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                StreamProof = !StreamProof;
                // Tambah hook screenshot di sini nanti
            }]];

            [menu addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:nil]];

            [UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:menu animated:YES completion:nil];
        } else {
            // Menu tutup (untuk test popup)
            UIAlertController *close = [UIAlertController alertControllerWithTitle:@"Azurite External" message:@"Menu Hidden" preferredStyle:UIAlertActionStyleAlert];
            [close addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:close animated:YES completion:nil];
        }
    }
}
%end

%ctor {
    @autoreleasepool {
        ptrace(PT_DENY_ATTACH, 0, 0, 0);

        void* il2cpp = dlopen("libil2cpp.so", RTLD_LAZY);
        if (il2cpp) {
            // Test hook simple (boleh tambah fitur sebenar nanti)
        }
    }
}
