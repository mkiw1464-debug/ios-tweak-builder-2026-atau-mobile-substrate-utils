// Tweak.xm - Azurite External (kemaskini Feb 2026)
// Triple tap 3 jari 3 kali untuk toggle menu

#include <substrate.h>
#include <dlfcn.h>
#include <UIKit/UIKit.h>

// Config fitur (toggle dari menu)
static BOOL EnableAimbot = NO;
static BOOL StreamProof = NO;

%hook UIWindow
- (void)becomeKeyWindow {
    %orig;

    // Gesture triple tap 3 jari
    UITapGestureRecognizer *tripleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(azuriteMenuToggle:)];
    tripleTap.numberOfTapsRequired = 3;
    tripleTap.numberOfTouchesRequired = 3;
    tripleTap.cancelsTouchesInView = NO;  // biar game masih respon touch
    [self addGestureRecognizer:tripleTap];
}

%new
- (void)azuriteMenuToggle:(UITapGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        static BOOL menuVisible = NO;
        menuVisible = !menuVisible;

        // Dapatkan root VC moden (ganti keyWindow deprecated)
        UIViewController *rootVC = nil;
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                rootVC = scene.windows.firstObject.rootViewController;
                break;
            }
        }
        if (!rootVC) return;

        if (menuVisible) {
            // Menu muncul - popup dengan toggle
            UIAlertController *menu = [UIAlertController alertControllerWithTitle:@"Azurite External" message:@"Menu Toggle" preferredStyle:UIAlertControllerStyleAlert];

            // Toggle Aimbot
            [menu addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Aimbot: %@", EnableAimbot ? @"ON" : @"OFF"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                EnableAimbot = !EnableAimbot;
                // Nanti tambah logic aimbot di sini
            }]];

            // Toggle Hide Rec
            [menu addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Hide Rec: %@", StreamProof ? @"ON" : @"OFF"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                StreamProof = !StreamProof;
                // Nanti tambah hook screenshot di sini
            }]];

            [menu addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:nil]];

            [rootVC presentViewController:menu animated:YES completion:nil];
        } else {
            // Menu tutup
            UIAlertController *close = [UIAlertController alertControllerWithTitle:@"Azurite External" message:@"Menu Hidden" preferredStyle:UIAlertControllerStyleAlert];
            [close addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [rootVC presentViewController:close animated:YES completion:nil];
        }
    }
}
%end

%ctor {
    @autoreleasepool {
        // Test dlopen libil2cpp
        void* il2cpp = dlopen("libil2cpp.so", RTLD_LAZY);
        if (il2cpp) {
            // Placeholder - tambah hook sebenar nanti
        }
    }
}
