#import "menu.h"

// ─────────────────────────────────────────────────────────────────────────────
//  tweak.xm  —  Logos entry point
//  Hooks the game's main application delegate to inject the floating menu.
//  Change the hook class names to match the actual game binary if needed.
// ─────────────────────────────────────────────────────────────────────────────

// ── Preference keys ──────────────────────────────────────────────────────────
#define kPrefDomain  @"com.cheatmenu.prefs"

static inline BOOL PrefBool(NSString *key, BOOL def) {
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:
        [NSString stringWithFormat:@"/var/mobile/Library/Preferences/%@.plist", kPrefDomain]];
    return d[key] ? [d[key] boolValue] : def;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Hook: UIApplication  (safe universal hook for any game)
// ─────────────────────────────────────────────────────────────────────────────
%hook UIApplication

- (void)_run {
    %orig;
}

%end

// ─────────────────────────────────────────────────────────────────────────────
//  Hook: UIWindow — intercept the first key window to inject our overlay
// ─────────────────────────────────────────────────────────────────────────────
%hook UIWindow

- (void)makeKeyAndVisible {
    %orig;
    // Only inject once into the very first game window
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
            dispatch_get_main_queue(),
            ^{ [MenuWindow.sharedMenu show]; }
        );
    });
}

%end

// ─────────────────────────────────────────────────────────────────────────────
//  Hook: UIViewController  — attach a floating trigger button on every VC
//  so the menu can be reopened after closing.
// ─────────────────────────────────────────────────────────────────────────────
static UIButton *_triggerButton = nil;

%hook UIViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;

    // Avoid adding multiple triggers
    if (_triggerButton && _triggerButton.superview) return;

    // Skip our own MenuViewController
    if ([self isKindOfClass:[MenuViewController class]]) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (_triggerButton) [_triggerButton removeFromSuperview];

        _triggerButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _triggerButton.frame = CGRectMake(10, 80, 46, 46);

        // Circular dark button with grid icon
        _triggerButton.backgroundColor =
            [UIColor colorWithRed:0.09 green:0.13 blue:0.21 alpha:0.85];
        _triggerButton.layer.cornerRadius  = 23;
        _triggerButton.layer.masksToBounds = YES;
        _triggerButton.layer.borderColor   =
            [UIColor colorWithRed:0.20 green:0.30 blue:0.45 alpha:0.6].CGColor;
        _triggerButton.layer.borderWidth = 1.0f;

        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration
            configurationWithPointSize:18 weight:UIImageSymbolWeightMedium];
        UIImage *icon = [[UIImage systemImageNamed:@"square.grid.2x2.fill"
                                  withConfiguration:cfg]
                         imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_triggerButton setImage:icon forState:UIControlStateNormal];
        _triggerButton.tintColor = [UIColor colorWithRed:0.30 green:0.63 blue:0.93 alpha:1.0];

        [_triggerButton addTarget:[MenuWindow sharedMenu]
                           action:@selector(toggle)
                 forControlEvents:UIControlEventTouchUpInside];

        // Drag support for the trigger button
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
            initWithTarget:_triggerButton
                    action:@selector(_dragTrigger:)];
        // We handle pan through a category below
        [_triggerButton addGestureRecognizer:pan];

        _triggerButton.layer.shadowColor   = [UIColor blackColor].CGColor;
        _triggerButton.layer.shadowOpacity = 0.4f;
        _triggerButton.layer.shadowRadius  = 6.0f;
        _triggerButton.layer.shadowOffset  = CGSizeMake(0, 2);

        [self.view addSubview:_triggerButton];
        [self.view bringSubviewToFront:_triggerButton];
    });
}

%end

// ─────────────────────────────────────────────────────────────────────────────
//  Category: draggable trigger button
// ─────────────────────────────────────────────────────────────────────────────
@interface UIButton (MenuDrag)
- (void)_dragTrigger:(UIPanGestureRecognizer *)pan;
@end

@implementation UIButton (MenuDrag)
- (void)_dragTrigger:(UIPanGestureRecognizer *)pan {
    CGPoint t = [pan translationInView:self.superview];
    if (pan.state == UIGestureRecognizerStateChanged) {
        CGPoint center = self.center;
        center.x += t.x;
        center.y += t.y;
        // Clamp within screen bounds
        CGSize sz = [UIScreen mainScreen].bounds.size;
        center.x = MAX(30, MIN(center.x, sz.width  - 30));
        center.y = MAX(50, MIN(center.y, sz.height - 50));
        self.center = center;
        [pan setTranslation:CGPointZero inView:self.superview];
    }
}
@end

// ─────────────────────────────────────────────────────────────────────────────
//  AIMBOT logic stub
//  Replace method names with the actual game's methods found via reverse engineering.
// ─────────────────────────────────────────────────────────────────────────────

/*
// Example — uncomment and replace class/method names:

%hook SomeAimController

- (void)updateAimTarget:(id)target {
    if (PrefBool(@"enableAimbot", NO)) {
        // Aimbot logic here
        %orig(target);
    }
}

- (BOOL)shouldFireAtTarget:(id)target {
    if (PrefBool(@"autoFire", NO)) return YES;
    return %orig;
}

%end
*/

// ─────────────────────────────────────────────────────────────────────────────
//  Constructor — called when dylib is injected
// ─────────────────────────────────────────────────────────────────────────────
%ctor {
    @autoreleasepool {
        NSLog(@"[CheatMenu] dylib loaded successfully.");
        %init;
    }
}

%dtor {
    NSLog(@"[CheatMenu] dylib unloaded.");
}
