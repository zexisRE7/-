#pragma once
#import <UIKit/UIKit.h>

// ─── Colors ───────────────────────────────────────────────────────────────────
#define kColorBG          [UIColor colorWithRed:0.09 green:0.13 blue:0.21 alpha:1.0]
#define kColorPanel       [UIColor colorWithRed:0.11 green:0.16 blue:0.25 alpha:0.97]
#define kColorRow         [UIColor colorWithRed:0.13 green:0.18 blue:0.28 alpha:1.0]
#define kColorRowActive   [UIColor colorWithRed:0.15 green:0.21 blue:0.33 alpha:1.0]
#define kColorSidebar     [UIColor colorWithRed:0.08 green:0.11 blue:0.18 alpha:1.0]
#define kColorBlue        [UIColor colorWithRed:0.30 green:0.63 blue:0.93 alpha:1.0]
#define kColorBlueLight   [UIColor colorWithRed:0.38 green:0.70 blue:0.98 alpha:1.0]
#define kColorBlueDim     [UIColor colorWithRed:0.18 green:0.35 blue:0.58 alpha:1.0]
#define kColorToggleOff   [UIColor colorWithRed:0.20 green:0.25 blue:0.36 alpha:1.0]
#define kColorToggleOn    [UIColor colorWithRed:0.30 green:0.63 blue:0.93 alpha:1.0]
#define kColorText        [UIColor colorWithWhite:0.95 alpha:1.0]
#define kColorSubtext     [UIColor colorWithWhite:0.55 alpha:1.0]
#define kColorOrange      [UIColor colorWithRed:1.0  green:0.55 blue:0.10 alpha:1.0]
#define kColorBorder      [UIColor colorWithRed:0.20 green:0.30 blue:0.45 alpha:0.6]

// ─── Tab identifiers ─────────────────────────────────────────────────────────
typedef NS_ENUM(NSInteger, MenuTab) {
    MenuTabUI        = 0,
    MenuTabAimbot    = 1,
    MenuTabGamepad   = 2,
    MenuTabTools     = 3,
    MenuTabProfile   = 4,
};

// ─── Toggle item model ────────────────────────────────────────────────────────
@interface ToggleItem : NSObject
@property (nonatomic, copy)   NSString *title;
@property (nonatomic, copy)   NSString *subtitle;   // nil = no subtitle
@property (nonatomic, copy)   NSString *warning;    // nil = no orange warning
@property (nonatomic, assign) BOOL      isOn;
@property (nonatomic, copy)   NSString *key;        // UserDefaults key
+ (instancetype)itemTitle:(NSString *)title
                 subtitle:(NSString *)subtitle
                  warning:(NSString *)warning
                      key:(NSString *)key
                     isOn:(BOOL)isOn;
@end

// ─── Custom toggle switch ─────────────────────────────────────────────────────
@interface MenuToggleSwitch : UIControl
@property (nonatomic, assign, getter=isOn) BOOL on;
- (void)setOn:(BOOL)on animated:(BOOL)animated;
@end

// ─── Single toggle row ────────────────────────────────────────────────────────
@interface ToggleRowView : UIView
@property (nonatomic, strong) ToggleItem       *item;
@property (nonatomic, strong) MenuToggleSwitch *toggle;
- (instancetype)initWithItem:(ToggleItem *)item;
@end

// ─── Snowfall particle layer ──────────────────────────────────────────────────
@interface SnowfallView : UIView
- (void)startSnow;
- (void)stopSnow;
@end

// ─── Sidebar circular icon button ────────────────────────────────────────────
@interface SidebarButton : UIButton
@property (nonatomic, assign) MenuTab tab;
@property (nonatomic, assign) BOOL    isActive;
- (void)setActive:(BOOL)active animated:(BOOL)animated;
@end

// ─── Top navigation bar ───────────────────────────────────────────────────────
@interface MenuNavBar : UIView
@property (nonatomic, strong) UILabel      *titleLabel;
@property (nonatomic, strong) UIImageView  *titleIcon;
@property (nonatomic, strong) UIButton     *saveButton;
@property (nonatomic, strong) UIButton     *moonButton;
@property (nonatomic, strong) UIButton     *closeButton;
- (void)setTabTitle:(NSString *)title iconName:(NSString *)sfName;
@end

// ─── Scrollable content panel ────────────────────────────────────────────────
@interface MenuContentView : UIView
- (void)loadItems:(NSArray<ToggleItem *> *)items;
- (void)reloadData;
@end

// ─── Main floating menu window ───────────────────────────────────────────────
@interface MenuWindow : UIWindow
+ (instancetype)sharedMenu;
- (void)show;
- (void)hide;
- (void)toggle;
@property (nonatomic, assign) BOOL menuVisible;
@end

// ─── Root view controller ─────────────────────────────────────────────────────
@interface MenuViewController : UIViewController
@property (nonatomic, assign) MenuTab       currentTab;
@property (nonatomic, strong) SnowfallView  *snowView;
@property (nonatomic, strong) UIView        *sidebarView;
@property (nonatomic, strong) UIView        *panelView;
@property (nonatomic, strong) MenuNavBar    *navBar;
@property (nonatomic, strong) MenuContentView *contentView;
@property (nonatomic, strong) NSArray<SidebarButton *> *sidebarButtons;

- (void)switchToTab:(MenuTab)tab animated:(BOOL)animated;
@end
