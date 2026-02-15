// Tweak.xm - Azurite External v3.0 (floating menu + full features)
// Triple tap 3 fingers 3 times → toggle menu
// Compile rootless, inject via eSign / TrollStore

#include <substrate.h>
#include <dlfcn.h>
#include <UIKit/UIKit.h>
#include <CoreGraphics/CoreGraphics.h>
#include <mach/mach.h>

// Config global
static BOOL menuVisible = NO;
static BOOL EnableAimbot = NO;
static int AimBone = 0; // 0=Head, 1=Neck, 2=Body
static BOOL EnableESP = NO;
static int ESPMode = 0; // 0=Line, 1=Box, 2=Skeleton, 3=Distance+Health
static BOOL SilentAim = NO;
static BOOL StreamProof = YES;

// Floating menu view
static UIView *menuView = nil;
static CGPoint lastPanPoint;

// Offsets placeholder – UPDATE DENGAN DUMP TERKINI (Il2CppDumper OB52/53)
uintptr_t OFF_LOCAL_PLAYER = 0x1A8C1F0;
uintptr_t OFF_PLAYER_LIST  = 0x1A7D9A8 + 0x120;
uintptr_t OFF_HEAD_BONE    = 0x140 + 0x90;
uintptr_t OFF_NECK_BONE    = 0x154 + 0x90;
uintptr_t OFF_BODY_BONE    = 0x168 + 0x90;
uintptr_t OFF_HEALTH       = 0x1A4E720;
uintptr_t OFF_VISIBLE      = 0x1B2D410;

// Utils
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

        if (menuVisible) {
            if (!menuView) {
                menuView = [[UIView alloc] initWithFrame:CGRectMake(40, 120, 260, 420)];
                menuView.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.12 alpha:0.95];
                menuView.layer.cornerRadius = 18;
                menuView.layer.borderWidth = 2;
                menuView.layer.borderColor = [UIColor colorWithRed:0 green:0.85 blue:1 alpha:0.8].CGColor;
                menuView.clipsToBounds = YES;

                // Title bar
                UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 260, 34)];
                title.text = @"Azurite External";
                title.textColor = [UIColor cyanColor];
                title.textAlignment = NSTextAlignmentCenter;
                title.font = [UIFont boldSystemFontOfSize:20];
                [menuView addSubview:title];

                // Draggable pan
                UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragMenu:)];
                [menuView addGestureRecognizer:pan];

                // Aimbot toggle + bone selector
                UISwitch *aimSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(180, 60, 0, 0)];
                aimSwitch.on = EnableAimbot;
                [aimSwitch addTarget:self action:@selector(toggleAimbot:) forControlEvents:UIControlEventValueChanged];
                [menuView addSubview:aimSwitch];

                UILabel *aimLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 60, 150, 30)];
                aimLabel.text = @"Aimbot";
                aimLabel.textColor = [UIColor whiteColor];
                [menuView addSubview:aimLabel];

                UISegmentedControl *boneSeg = [[UISegmentedControl alloc] initWithItems:@[@"Head", @"Neck", @"Body"]];
                boneSeg.frame = CGRectMake(20, 100, 220, 34);
                boneSeg.selectedSegmentIndex = AimBone;
                [boneSeg addTarget:self action:@selector(changeBone:) forControlEvents:UIControlEventValueChanged];
                [menuView addSubview:boneSeg];

                // ESP toggle + mode
                UISwitch *espSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(180, 150, 0, 0)];
                espSwitch.on = EnableESP;
                [espSwitch addTarget:self action:@selector(toggleESP:) forControlEvents:UIControlEventValueChanged];
                [menuView addSubview:espSwitch];

                UILabel *espLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 150, 150, 30)];
                espLabel.text = @"ESP";
                espLabel.textColor = [UIColor whiteColor];
                [menuView addSubview:espLabel];

                UISegmentedControl *espModeSeg = [[UISegmentedControl alloc] initWithItems:@[@"Line", @"Box", @"Skel", @"Dist"]];
                espModeSeg.frame = CGRectMake(20, 190, 220, 34);
                espModeSeg.selectedSegmentIndex = ESPMode;
                [espModeSeg addTarget:self action:@selector(changeESPMode:) forControlEvents:UIControlEventValueChanged];
                [menuView addSubview:espModeSeg];

                // Silent Aim toggle
                UISwitch *silentSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(180, 240, 0, 0)];
                silentSwitch.on = SilentAim;
                [silentSwitch addTarget:self action:@selector(toggleSilentAim:) forControlEvents:UIControlEventValueChanged];
                [menuView addSubview:silentSwitch];

                UILabel *silentLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 240, 150, 30)];
                silentLabel.text = @"Silent Aim";
                silentLabel.textColor = [UIColor whiteColor];
                [menuView addSubview:silentLabel];

                // Streamproof toggle
                UISwitch *streamSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(180, 290, 0, 0)];
                streamSwitch.on = StreamProof;
                [streamSwitch addTarget:self action:@selector(toggleStreamProof:) forControlEvents:UIControlEventValueChanged];
                [menuView addSubview:streamSwitch];

                UILabel *streamLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 290, 150, 30)];
                streamLabel.text = @"StreamProof";
                streamLabel.textColor = [UIColor whiteColor];
                [menuView addSubview:streamLabel];

                // Close button
                UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
                closeBtn.frame = CGRectMake(20, 350, 220, 40);
                closeBtn.backgroundColor = [UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:0.9];
                [closeBtn setTitle:@"Close Menu" forState:UIControlStateNormal];
                [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                closeBtn.layer.cornerRadius = 12;
                [closeBtn addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
                [menuView addSubview:closeBtn];

                [[UIApplication sharedApplication].windows.firstObject addSubview:menuView];
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

// Streamproof hooks (screenshot + record)
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

// Placeholder aimbot/ESP/silent hooks (update offsets & logic)
%hook PlayerMovement
- (void)Update {
    %orig;
    if (EnableAimbot || SilentAim) {
        // Placeholder - tambah real aim logic (get closest, calc angle, write bullet dir)
        // Example: if (SilentAim) write bullet vector
    }
}
%end

%ctor {
    @autoreleasepool {
        // Anti detect basic
        ptrace(PT_DENY_ATTACH, 0, 0, 0);

        void* il2cpp = dlopen("libil2cpp.so", RTLD_LAZY);
        if (il2cpp) {
            // Add real hooks here (MSHookFunction or LSPlant)
        }
    }
}
