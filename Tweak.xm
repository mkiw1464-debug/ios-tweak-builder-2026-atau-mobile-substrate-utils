// Tweak.xm - Azurite External v3.5 (iOS 17–18.2)
// Triple tap 3 jari 3 kali → toggle floating menu
// Compile rootless, inject via eSign / TrollStore

#include <substrate.h>
#include <dlfcn.h>
#include <UIKit/UIKit.h>
#include <CoreGraphics/CoreGraphics.h>
#include <mach/mach.h>

// Config
static BOOL menuVisible = NO;
static BOOL EnableAimbot = NO;
static int AimBone = 0;           // 0=Head, 1=Neck, 2=Body
static BOOL EnableESP = NO;
static int ESPMode = 0;           // 0=Line, 1=Box, 2=Skeleton, 3=Distance+Health
static BOOL SilentAim = NO;
static BOOL StreamProof = YES;

// Floating menu
static UIView *menuView = nil;
static CGPoint lastPanPoint;

// Antiban spoof UUID
%hook UIDevice
- (NSUUID *)identifierForVendor {
    static NSUUID *spoof = nil;
    if (!spoof) {
        spoof = [[NSUUID alloc] initWithUUIDString:[NSString stringWithFormat:@"E%@", [[NSUUID UUID] UUIDString]]];
    }
    return spoof;
}
%end

%hook ASIdentifierManager
- (NSUUID *)advertisingIdentifier {
    return [[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"];
}
%end

// Gesture & menu (scene-aware iOS 17+)
%hook UIWindow
- (void)becomeKeyWindow {
    %orig;

    UITapGestureRecognizer *tripleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleAzuriteMenu:)];
    tripleTap.numberOfTapsRequired = 3;
    tripleTap.numberOfTouchesRequired = 3;
    tripleTap.cancelsTouchesInView = NO;
    [self addGestureRecognizer:tripleTap];
}

%new
- (void)toggleAzuriteMenu:(UITapGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        menuVisible = !menuVisible;

        UIViewController *rootVC = nil;
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive) {
                rootVC = scene.windows.firstObject.rootViewController;
                break;
            }
        }
        if (!rootVC) rootVC = [UIApplication sharedApplication].delegate.window.rootViewController;
        if (!rootVC) return;

        if (menuVisible) {
            if (!menuView) {
                menuView = [[UIView alloc] initWithFrame:CGRectMake(40, 120, 280, 480)];
                menuView.backgroundColor = [UIColor colorWithRed:0.07 green:0.07 blue:0.11 alpha:0.96];
                menuView.layer.cornerRadius = 20;
                menuView.layer.borderWidth = 2;
                menuView.layer.borderColor = [UIColor colorWithRed:0 green:0.9 blue:1 alpha:0.85].CGColor;
                menuView.clipsToBounds = YES;

                UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 280, 40)];
                title.text = @"Azurite External";
                title.textColor = [UIColor cyanColor];
                title.textAlignment = NSTextAlignmentCenter;
                title.font = [UIFont boldSystemFontOfSize:22];
                [menuView addSubview:title];

                UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragMenu:)];
                [menuView addGestureRecognizer:pan];

                // Aimbot toggle + bone selector
                UISwitch *aimSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(200, 70, 0, 0)];
                aimSwitch.on = EnableAimbot;
                [aimSwitch addTarget:self action:@selector(toggleAimbot:) forControlEvents:UIControlEventValueChanged];
                [menuView addSubview:aimSwitch];

                UILabel *aimLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 70, 170, 30)];
                aimLabel.text = @"Aimbot";
                aimLabel.textColor = [UIColor whiteColor];
                [menuView addSubview:aimLabel];

                UISegmentedControl *boneSeg = [[UISegmentedControl alloc] initWithItems:@[@"Head", @"Neck", @"Body"]];
                boneSeg.frame = CGRectMake(20, 110, 240, 36);
                boneSeg.selectedSegmentIndex = AimBone;
                [boneSeg addTarget:self action:@selector(changeBone:) forControlEvents:UIControlEventValueChanged];
                [menuView addSubview:boneSeg];

                // ESP toggle + mode
                UISwitch *espSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(200, 160, 0, 0)];
                espSwitch.on = EnableESP;
                [espSwitch addTarget:self action:@selector(toggleESP:) forControlEvents:UIControlEventValueChanged];
                [menuView addSubview:espSwitch];

                UILabel *espLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 160, 170, 30)];
                espLabel.text = @"ESP";
                espLabel.textColor = [UIColor whiteColor];
                [menuView addSubview:espLabel];

                UISegmentedControl *espModeSeg = [[UISegmentedControl alloc] initWithItems:@[@"Line", @"Box", @"Skeleton", @"Dist"]];
                espModeSeg.frame = CGRectMake(20, 200, 240, 36);
                espModeSeg.selectedSegmentIndex = ESPMode;
                [espModeSeg addTarget:self action:@selector(changeESPMode:) forControlEvents:UIControlEventValueChanged];
                [menuView addSubview:espModeSeg];

                // Silent Aim toggle
                UISwitch *silentSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(200, 250, 0, 0)];
                silentSwitch.on = SilentAim;
                [silentSwitch addTarget:self action:@selector(toggleSilentAim:) forControlEvents:UIControlEventValueChanged];
                [menuView addSubview:silentSwitch];

                UILabel *silentLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 250, 170, 30)];
                silentLabel.text = @"Silent Aim";
                silentLabel.textColor = [UIColor whiteColor];
                [menuView addSubview:silentLabel];

                // Streamproof toggle
                UISwitch *streamSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(200, 300, 0, 0)];
                streamSwitch.on = StreamProof;
                [streamSwitch addTarget:self action:@selector(toggleStreamProof:) forControlEvents:UIControlEventValueChanged];
                [menuView addSubview:streamSwitch];

                UILabel *streamLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 300, 170, 30)];
                streamLabel.text = @"StreamProof";
                streamLabel.textColor = [UIColor whiteColor];
                [menuView addSubview:streamLabel];

                // Close button
                UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
                closeBtn.frame = CGRectMake(20, 420, 240, 44);
                closeBtn.backgroundColor = [UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:0.9];
                [closeBtn setTitle:@"Close Menu" forState:UIControlStateNormal];
                [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                closeBtn.layer.cornerRadius = 14;
                [closeBtn addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
                [menuView addSubview:closeBtn];

                [rootVC.view addSubview:menuView];
            }
        } else {
            [menuView removeFromSuperview];
            menuView = nil;
        }
    }
}

%new - (void)dragMenu:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:menuView.superview];
    if (pan.state == UIGestureRecognizerStateBegan) lastPanPoint = menuView.center;
    menuView.center = CGPointMake(lastPanPoint.x + translation.x, lastPanPoint.y + translation.y);
}

%new - (void)toggleAimbot:(UISwitch *)sender { EnableAimbot = sender.isOn; }
%new - (void)changeBone:(UISegmentedControl *)seg { AimBone = (int)seg.selectedSegmentIndex; }
%new - (void)toggleESP:(UISwitch *)sender { EnableESP = sender.isOn; }
%new - (void)changeESPMode:(UISegmentedControl *)seg { ESPMode = (int)seg.selectedSegmentIndex; }
%new - (void)toggleSilentAim:(UISwitch *)sender { SilentAim = sender.isOn; }
%new - (void)toggleStreamProof:(UISwitch *)sender { StreamProof = sender.isOn; }
%new - (void)closeMenu {
    menuVisible = NO;
    [menuView removeFromSuperview];
    menuView = nil;
}

// Streamproof (screenshot + record + AVFoundation)
%hook UIScreen
+ (UIImage *)captureScreen {
    if (StreamProof) return nil;
    return %orig;
}
%end

%hook RPSystemBroadcastPickerViewController
- (void)viewDidLoad {
    if (StreamProof) [self dismissViewControllerAnimated:YES completion:nil];
    else %orig;
}
%end

// Placeholder aimbot/ESP/silent (update offsets + add real logic)
%hook PlayerMovement
- (void)Update {
    %orig;
    if (EnableAimbot || SilentAim) {
        // Placeholder – real logic: find closest, calc angle, redirect bullet vector kalau SilentAim
        // Tambah random miss 5-15% untuk antibehaviour
        if (arc4random_uniform(100) > 10) {
            // aim logic
        }
    }
}
%end

%ctor {
    @autoreleasepool {
        void* il2cpp = dlopen("libil2cpp.so", RTLD_LAZY);
        if (il2cpp) {
            // Tambah real hooks nanti
        }
    }
}
