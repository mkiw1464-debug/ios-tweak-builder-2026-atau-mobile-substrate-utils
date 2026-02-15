// Tweak.mm - Azurite External (kemaskini Feb 2026)
// Compile: Theos rootless, target bundle com.garena.game.ff

#include <substrate.h>
#include <dlfcn.h>
#include <pthread.h>
#include <sys/ptrace.h>
#include <mach/mach.h>
#include <string>
#include <vector>
#include <random>
#include <ctime>
#include <Preferences/Preferences.h>

#define AZURITE_VERSION "External 1.0 – Feb 2026"

// ────────────────────────────────────────────────
// Offsets (KEMASKINI DENGAN DUMP TERKINI SETIAP OB!)
// Contoh offset OB52-ish – dump guna Il2CppDumper
uintptr_t OFF_LOCAL_PLAYER       = 0x1A8C1F0;
uintptr_t OFF_PLAYER_LIST        = 0x1A7D9A8 + 0x120;
uintptr_t OFF_HEALTH             = 0x1A4E720;
uintptr_t OFF_TEAM               = 0x1A5F1B8;
uintptr_t OFF_HEAD_BONE          = 0x140 + 0x90;
uintptr_t OFF_NECK_BONE          = 0x154 + 0x90;
uintptr_t OFF_BODY_BONE          = 0x168 + 0x90;
uintptr_t OFF_VISIBLE            = 0x1B2D410;
uintptr_t OFF_BULLET_DIRECTION   = 0x1D2E100 + 0x28;

// ────────────────────────────────────────────────
// Config dari plist (Settings app)
bool   az_aimbot         = true;
bool   az_silent         = true;
int    az_bone           = 0;        // 0=head, 1=neck, 2=body
float  az_fov            = 14.0f;
bool   az_esp            = true;
bool   az_no_recoil      = true;
bool   az_streamproof    = true;

// Globals
void*  g_local           = nullptr;
Vector3 (*WorldToScreenPoint)(void*, Vector3);

// ────────────────────────────────────────────────
// Load preferences dari com.azurite.external.plist
static void loadPrefs() {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.azurite.external.plist"];
    if (prefs) {
        az_aimbot      = [prefs objectForKey:@"az_aimbot"]     ? [[prefs objectForKey:@"az_aimbot"] boolValue]     : az_aimbot;
        az_silent      = [prefs objectForKey:@"az_silent"]     ? [[prefs objectForKey:@"az_silent"] boolValue]     : az_silent;
        az_fov         = [prefs objectForKey:@"az_fov"]        ? [[prefs objectForKey:@"az_fov"] floatValue]       : az_fov;
        az_bone        = [prefs objectForKey:@"az_bone"]       ? [[prefs objectForKey:@"az_bone"] intValue]        : az_bone;
        az_esp         = [prefs objectForKey:@"az_esp"]        ? [[prefs objectForKey:@"az_esp"] boolValue]        : az_esp;
        az_no_recoil   = [prefs objectForKey:@"az_no_recoil"]  ? [[prefs objectForKey:@"az_no_recoil"] boolValue]   : az_no_recoil;
        az_streamproof = [prefs objectForKey:@"az_streamproof"] ? [[prefs objectForKey:@"az_streamproof"] boolValue] : az_streamproof;
    }
}

// ────────────────────────────────────────────────
// Bypass antiban
static void anti_debug() {
    ptrace(PT_DENY_ATTACH, 0, 0, 0);
}

static const char* (*orig_UUID)();
static const char* hooked_UUID() {
    static std::string spoof = "AzSpoof-" + std::to_string(rand() % 99999999 + 10000000);
    return spoof.c_str();
}

static bool (*orig_Capture)(const char*);
static bool hooked_Capture(const char* path) {
    return az_streamproof ? true : orig_Capture(path);
}

// ────────────────────────────────────────────────
// Utils
struct Vector3 { float x, y, z; };

Vector3 get_bone(void* player, int bone) {
    uintptr_t off = (bone == 0 ? OFF_HEAD_BONE : bone == 1 ? OFF_NECK_BONE : OFF_BODY_BONE);
    return *(Vector3*)((uintptr_t)player + off);
}

bool is_valid_target(void* p) {
    if (!p) return false;
    int hp = *(int*)((uintptr_t)p + OFF_HEALTH);
    if (hp <= 0 || hp > 200) return false;
    if (!*(uint8_t*)((uintptr_t)p + OFF_VISIBLE)) return false;
    // team check (tambah kalau ada offset team)
    return true;
}

void* find_closest_target() {
    // Placeholder: scan player list (real impl perlukan loop entity manager)
    // Contoh naive: cari memory range & check signature player object
    return nullptr; // KEMASKINI: tambah logic scan sebenar
}

void apply_silent_aim(void* local, void* target) {
    Vector3 src = get_bone(local, 0);
    Vector3 dst = get_bone(target, az_bone);
    Vector3 dir = {dst.x - src.x, dst.y - src.y, dst.z - src.z};
    float len = sqrtf(dir.x*dir.x + dir.y*dir.y + dir.z*dir.z);
    if (len < 0.01f) return;

    dir.x /= len; dir.y /= len; dir.z /= len;
    // humanize micro-random (anti behaviour detect)
    dir.x += (rand() % 100 - 50) / 12000.0f;
    dir.y += (rand() % 100 - 50) / 12000.0f;

    *(Vector3*)((uintptr_t)local + OFF_BULLET_DIRECTION) = dir;
}

// ────────────────────────────────────────────────
// Hooked Update
void (*orig_Update)(void*);
void hooked_Update(void* self) {
    bool is_local = *(bool*)((uintptr_t)self + 0x18); // approx IsLocalPlayer
    if (is_local) {
        g_local = self;

        if (az_aimbot) {
            void* target = find_closest_target();
            if (target && is_valid_target(target)) {
                if (az_silent) apply_silent_aim(self, target);
            }
        }

        // ESP logic (tambah kalau ada draw hook)
    }

    orig_Update(self);
}

// ────────────────────────────────────────────────
// Entry point
%ctor {
    @autoreleasepool {
        srand(time(NULL));

        // Load preferences awal
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
            NULL, (CFNotificationCallback)loadPrefs,
            CFSTR("com.azurite.external/PreferencesChanged"), NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately);
        loadPrefs();

        void* il2cpp = dlopen("libil2cpp.so", RTLD_LAZY);
        if (!il2cpp) return;

        WorldToScreenPoint = (decltype(WorldToScreenPoint))dlsym(il2cpp, "WorldToScreenPoint");

        void* update_sym = dlsym(il2cpp, "_ZN12PlayerMovement6UpdateEv");
        if (update_sym) MSHookFunction(update_sym, (void*)hooked_Update, (void**)&orig_Update);

        // Bypass hooks
        MSHookFunction((void*)dlsym(RTLD_DEFAULT, "-[NSUUID UUIDString]"), (void*)hooked_UUID, (void**)&orig_UUID);
        MSHookFunction((void*)dlsym(RTLD_DEFAULT, "CaptureScreenshot"), (void*)hooked_Capture, (void**)&orig_Capture);

        anti_debug();
    }
}
