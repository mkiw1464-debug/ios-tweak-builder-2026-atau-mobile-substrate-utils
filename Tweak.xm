// Tweak.xm - Azurite External v2.1 (floating menu + full features)
// Trigger: Triple tap 3 fingers 3 times

#include <substrate.h>
#include <dlfcn.h>
#include <UIKit/UIKit.h>
#include <CoreGraphics/CoreGraphics.h>

// Config
static BOOL menuVisible = NO;
static BOOL EnableAimbot = NO;
static int AimBone = 0;           // 0 = Head, 1 = Neck, 2 = Body
static BOOL EnableESP = NO;
static int ESPMode = 0;           // 0 = Line, 1 = Box, 2 = Skeleton, 3 = Distance+Health
static BOOL SilentAim = NO;
static BOOL StreamProof = YES;

// Floating menu view
static UIView *menuView = nil;
static CGPoint lastPanPoint;

// Offsets placeholder (update dengan Il2CppDumper OB52/53)
uintptr_t OFF_LOCAL_PLAYER = 0x1A8C1F0;
uintptr_t OFF_PLAYER_LIST  = 0x1A7D9A8 + 0x120;
uintptr_t OFF_HEAD_BONE    = 0x140 + 0x90;
uintptr_t OFF_NECK_BONE    = 0x154 + 0x90;
uintptr_t OFF_BODY_BONE    = 0x168 + 0x90;

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
                menuView = [[UIView alloc] initWithFrame:CGRectMake(40, 120, 240, 380)];
                menuView.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.15 alpha:0.92];
                menuView.layer.cornerRadius = 16;
                menuView.layer.borderWidth = 2;
                menuView.layer.borderColor = [UIColor colorWithRed:0 green:0.8 blue:1 alpha:0.7].CGColor;
                menuView.clipsToBounds = YES;

                // Title
                UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 240, 30)];
                title.text = @"Azurite External";
                title.textColor = [UIColor cyanColor];
                title.textAlignment = NSTextAlignmentCenter;
                title.font = [UIFont boldSystemFontOfSize:18];
                [menuView addSubview:title];

                // Aimbot toggle
                UISwitch *aimSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(160, 60, 0, 0)];
                aimSwitch.on = EnableAimbot;
                [aimSwitch addTarget:self action:@selector(toggleAimbot:) forControlEvents:UIControlEventValueChanged];
                [menuView addSubview:aimSwitch];

                UILabel *aimLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 60, 130, 30)];
                aimLabel.text = @"Aimbot";
                aimLabel.textColor = [UIColor whiteColor];
                [menuView addSubview:aimLabel];

                // Bone selector
                UISegmentedControl *boneSeg = [[UISegmentedControl alloc] initWithItems:@[@"Head", @"Neck", @"Body"]];
                boneSeg.frame = CGRectMake(20, 100, 200, 30);
                boneSeg.selectedSegmentIndex = AimBone;
                [boneSeg addTarget:self action:@selector(changeBone:) forControlEvents:UIControlEventValueChanged];
                [menuView addSubview:boneSeg];

                // ESP toggle + mode
                UISwitch *espSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(160, 140, 0, 0)];
                espSwitch.on = EnableESP;
                [espSwitch addTarget:self action:@selector(toggleESP:) forControlEvents:UIControlEventValueChanged];
                [menuView addSubview:espSwitch];

                UILabel *espLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 140, 130, 30)];
                espLabel.text = @"ESP";
                espLabel.textColor = [UIColor whiteColor];
                [menuView addSubview:espLabel];

                UISegmentedControl *espModeSeg = [[UISegmentedControl alloc] initWithItems:@[@"Line", @"Box", @"Skel", @"Dist"]];
                espModeSeg.frame = CGRectMake(20, 180, 200, 30);
                espModeSeg.selectedSegmentIndex = ESPMode;
                [espModeSeg addTarget:self action:@selector(changeESPMode:) forControlEvents:UIControlEventValueChanged];
                [menuView addSubview:espModeSeg];

                // Silent Aim toggle
                UISwitch *silentSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(160, 220, 0, 0)];
                silentSwitch.on = SilentAim;
                [silentSwitch addTarget:self action:@selector(toggleSilentAim:) forControlEvents:UIControlEventValueChanged];
                [menuView addSubview:silentSwitch];

                UILabel *silentLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 220, 130, 30)];
                silentLabel.text = @"Silent Aim";
                silentLabel.textColor = [UIColor whiteColor];
                [menuView addSubview:silentLabel];

                // Streamproof toggle
                UISwitch *streamSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(160, 260, 0, 0)];
                streamSwitch.on = StreamProof;
                [streamSwitch addTarget:self action:@selector(toggleStreamProof:) forControlEvents:UIControlEventValueChanged];
                [menuView addSubview:streamSwitch];

                UILabel *streamLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 260, 130, 30)];
                streamLabel.text = @"StreamProof";
                streamLabel.textColor = [UIColor whiteColor];
                [menuView addSubview:streamLabel];

                // Draggable
                UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragMenu:)];
                [menuView addGestureRecognizer:pan];

                [[UIApplication sharedApplication].windows.firstObject addSubview:menuView];
            }
        } else {
            [menuView removeFromSuperview];
            menuView = nil;
        }
    }
}

%new
- (void)dragMenu:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:menuView.superview];
    if (pan.state == UIGestureRecognizerStateBegan) {
        lastPanPoint = menuView.center;
    }
    menuView.center = CGPointMake(lastPanPoint.x + translation.x, lastPanPoint.y + translation.y);
}

%new - (void)toggleAimbot:(UISwitch *)sender { EnableAimbot = sender.isOn; }
%new - (void)changeBone:(UISegmentedControl *)seg { AimBone = (int)seg.selectedSegmentIndex; }
%new - (void)toggleESP:(UISwitch *)sender { EnableESP = sender.isOn; }
%new - (void)changeESPMode:(UISegmentedControl *)seg { ESPMode = (int)seg.selectedSegmentIndex; }
%new - (void)toggleSilentAim:(UISwitch *)sender { SilentAim = sender.isOn; }
%new - (void)toggleStreamProof:(UISwitch *)sender { StreamProof = sender.isOn; }

// Placeholder hooks (update offsets + real logic)
%hook PlayerMovement
- (void)Update {
    %orig;
    if (EnableAimbot) {
        // Silent aim logic here
    }
}
%end

// Streamproof hook example
%hook UIScreen
+ (UIImage *)captureScreen {
    if (StreamProof) return nil;
    return %orig;
}
%end

%ctor {
    @autoreleasepool {
        void* il2cpp = dlopen("libil2cpp.so", RTLD_LAZY);
        if (il2cpp) {
            // Add real hooks here later
        }
    }
}
