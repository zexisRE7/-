#import "menu.h"
#import <QuartzCore/QuartzCore.h>

// ─────────────────────────────────────────────────────────────────────────────
#pragma mark - ToggleItem
// ─────────────────────────────────────────────────────────────────────────────
@implementation ToggleItem
+ (instancetype)itemTitle:(NSString *)title
                 subtitle:(NSString *)subtitle
                  warning:(NSString *)warning
                      key:(NSString *)key
                     isOn:(BOOL)isOn {
    ToggleItem *item  = [self new];
    item.title        = title;
    item.subtitle     = subtitle;
    item.warning      = warning;
    item.key          = key;
    item.isOn         = [[NSUserDefaults standardUserDefaults] objectForKey:key]
                            ? [[NSUserDefaults standardUserDefaults] boolForKey:key]
                            : isOn;
    return item;
}
@end

// ─────────────────────────────────────────────────────────────────────────────
#pragma mark - MenuToggleSwitch
// ─────────────────────────────────────────────────────────────────────────────
static CGFloat const kSwitchW  = 54.0f;
static CGFloat const kSwitchH  = 30.0f;
static CGFloat const kThumbSz  = 24.0f;
static CGFloat const kPad      = 3.0f;

@interface MenuToggleSwitch ()
@property (nonatomic, strong) CALayer     *trackLayer;
@property (nonatomic, strong) CALayer     *thumbLayer;
@property (nonatomic, strong) CALayer     *checkLayer;
@end

@implementation MenuToggleSwitch

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:CGRectMake(0,0,kSwitchW,kSwitchH)])) {
        [self _setup];
    }
    return self;
}

- (void)_setup {
    self.backgroundColor = [UIColor clearColor];

    _trackLayer = [CALayer layer];
    _trackLayer.frame        = self.bounds;
    _trackLayer.cornerRadius = kSwitchH / 2.0f;
    _trackLayer.masksToBounds = YES;
    [self.layer addSublayer:_trackLayer];

    _thumbLayer = [CALayer layer];
    _thumbLayer.frame        = CGRectMake(kPad, kPad, kThumbSz, kThumbSz);
    _thumbLayer.cornerRadius = kThumbSz / 2.0f;
    _thumbLayer.backgroundColor = [UIColor whiteColor].CGColor;
    _thumbLayer.shadowColor  = [UIColor blackColor].CGColor;
    _thumbLayer.shadowOpacity = 0.3f;
    _thumbLayer.shadowRadius  = 3.0f;
    _thumbLayer.shadowOffset  = CGSizeMake(0, 1);
    [self.layer addSublayer:_thumbLayer];

    // Checkmark sublayer (visible when ON)
    _checkLayer = [CALayer layer];
    _checkLayer.frame = _thumbLayer.bounds;
    _checkLayer.cornerRadius = kThumbSz / 2.0f;
    _checkLayer.backgroundColor = kColorToggleOn.CGColor;
    _checkLayer.opacity = 0.0f;
    [self.layer addSublayer:_checkLayer];

    [self _applyState:NO];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(_tapped)];
    [self addGestureRecognizer:tap];
}

- (void)_tapped {
    [self setOn:!_on animated:YES];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)setOn:(BOOL)on {
    [self setOn:on animated:NO];
}

- (void)setOn:(BOOL)on animated:(BOOL)animated {
    _on = on;
    if (animated) {
        [UIView animateWithDuration:0.22
                              delay:0
             usingSpringWithDamping:0.75
              initialSpringVelocity:0.5
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{ [self _applyState:on]; }
                         completion:nil];
    } else {
        [self _applyState:on];
    }
}

- (void)_applyState:(BOOL)on {
    if (on) {
        _trackLayer.backgroundColor = kColorToggleOn.CGColor;
        CGFloat tx = kSwitchW - kThumbSz - kPad;
        _thumbLayer.frame = CGRectMake(tx, kPad, kThumbSz, kThumbSz);
        // Draw checkmark via path in thumbLayer
        [self _drawCheckmarkOn:YES];
    } else {
        _trackLayer.backgroundColor = kColorToggleOff.CGColor;
        _thumbLayer.frame = CGRectMake(kPad, kPad, kThumbSz, kThumbSz);
        [self _drawCheckmarkOn:NO];
    }
}

- (void)_drawCheckmarkOn:(BOOL)on {
    // Remove old sublayers from thumb
    NSArray *subs = [_thumbLayer.sublayers copy];
    for (CALayer *l in subs) { [l removeFromSuperlayer]; }

    if (!on) return;

    // Thumb color stays white; add blue tint background
    _thumbLayer.backgroundColor = [UIColor whiteColor].CGColor;

    CAShapeLayer *check = [CAShapeLayer layer];
    check.frame = _thumbLayer.bounds;

    UIBezierPath *path = [UIBezierPath bezierPath];
    CGFloat cx = kThumbSz / 2.0f;
    CGFloat cy = kThumbSz / 2.0f;
    [path moveToPoint:    CGPointMake(cx - 5.5f, cy - 0.5f)];
    [path addLineToPoint: CGPointMake(cx - 1.5f, cy + 4.0f)];
    [path addLineToPoint: CGPointMake(cx + 5.5f, cy - 4.0f)];

    check.path        = path.CGPath;
    check.strokeColor = kColorToggleOn.CGColor;
    check.fillColor   = [UIColor clearColor].CGColor;
    check.lineWidth   = 2.2f;
    check.lineCap     = kCALineCapRound;
    check.lineJoin    = kCALineJoinRound;
    [_thumbLayer addSublayer:check];
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(kSwitchW, kSwitchH);
}
@end

// ─────────────────────────────────────────────────────────────────────────────
#pragma mark - ToggleRowView
// ─────────────────────────────────────────────────────────────────────────────
@implementation ToggleRowView

- (instancetype)initWithItem:(ToggleItem *)item {
    if ((self = [super initWithFrame:CGRectZero])) {
        _item = item;
        [self _setup];
    }
    return self;
}

- (void)_setup {
    self.backgroundColor = kColorRow;
    self.layer.cornerRadius = 14.0f;
    self.layer.masksToBounds = YES;
    self.layer.borderColor = kColorBorder.CGColor;
    self.layer.borderWidth = 0.5f;

    CGFloat padding = 16.0f;

    // Title label
    UILabel *titleLbl = [[UILabel alloc] init];
    titleLbl.translatesAutoresizingMaskIntoConstraints = NO;
    titleLbl.text      = _item.title;
    titleLbl.textColor = kColorText;
    titleLbl.font      = [UIFont systemFontOfSize:15.0f weight:UIFontWeightMedium];
    [self addSubview:titleLbl];

    // Toggle
    _toggle = [[MenuToggleSwitch alloc] initWithFrame:CGRectZero];
    _toggle.translatesAutoresizingMaskIntoConstraints = NO;
    [_toggle setOn:_item.isOn animated:NO];
    [_toggle addTarget:self action:@selector(_toggled:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:_toggle];

    // Constraints for title + toggle
    [NSLayoutConstraint activateConstraints:@[
        [titleLbl.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:padding],
        [titleLbl.topAnchor constraintEqualToAnchor:self.topAnchor constant:13.0f],
        [_toggle.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-padding],
        [_toggle.centerYAnchor constraintEqualToAnchor:titleLbl.centerYAnchor],
        [titleLbl.trailingAnchor constraintLessThanOrEqualToAnchor:_toggle.leadingAnchor constant:-8.0f],
    ]];

    CGFloat bottomAnchorY = 13.0f;

    // Optional subtitle
    if (_item.subtitle.length > 0) {
        UILabel *subLbl = [[UILabel alloc] init];
        subLbl.translatesAutoresizingMaskIntoConstraints = NO;
        subLbl.text      = _item.subtitle;
        subLbl.textColor = kColorSubtext;
        subLbl.font      = [UIFont systemFontOfSize:12.0f weight:UIFontWeightRegular];
        subLbl.numberOfLines = 0;
        [self addSubview:subLbl];
        [NSLayoutConstraint activateConstraints:@[
            [subLbl.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:padding],
            [subLbl.topAnchor constraintEqualToAnchor:titleLbl.bottomAnchor constant:3.0f],
            [subLbl.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-padding],
        ]];
        bottomAnchorY = 8.0f;

        if (_item.warning.length > 0) {
            UILabel *warnLbl = [[UILabel alloc] init];
            warnLbl.translatesAutoresizingMaskIntoConstraints = NO;
            warnLbl.text      = _item.warning;
            warnLbl.textColor = kColorOrange;
            warnLbl.font      = [UIFont systemFontOfSize:12.0f weight:UIFontWeightRegular];
            warnLbl.numberOfLines = 0;
            [self addSubview:warnLbl];
            [NSLayoutConstraint activateConstraints:@[
                [warnLbl.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:padding],
                [warnLbl.topAnchor constraintEqualToAnchor:subLbl.bottomAnchor constant:2.0f],
                [warnLbl.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-padding],
                [warnLbl.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-bottomAnchorY],
            ]];
        } else {
            [subLbl.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-bottomAnchorY].active = YES;
        }
    } else {
        [titleLbl.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-13.0f].active = YES;
    }
}

- (void)_toggled:(MenuToggleSwitch *)sw {
    _item.isOn = sw.isOn;
    [[NSUserDefaults standardUserDefaults] setBool:sw.isOn forKey:_item.key];
    [[NSUserDefaults standardUserDefaults] synchronize];

    // Animate row background
    [UIView animateWithDuration:0.18 animations:^{
        self.backgroundColor = sw.isOn ? kColorRowActive : kColorRow;
    }];
}
@end

// ─────────────────────────────────────────────────────────────────────────────
#pragma mark - SnowfallView
// ─────────────────────────────────────────────────────────────────────────────
@implementation SnowfallView {
    CAEmitterLayer *_emitter;
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    if (self.superview) [self startSnow];
}

- (void)startSnow {
    if (_emitter) return;
    _emitter = [CAEmitterLayer layer];
    _emitter.emitterShape    = kCAEmitterLayerLine;
    _emitter.emitterPosition = CGPointMake(self.bounds.size.width / 2.0f, -10);
    _emitter.emitterSize     = CGSizeMake(self.bounds.size.width, 1);
    _emitter.renderMode      = kCAEmitterLayerAdditive;

    CAEmitterCell *flake = [CAEmitterCell emitterCell];
    flake.name            = @"flake";
    flake.birthRate       = 3.0f;
    flake.lifetime        = 12.0f;
    flake.lifetimeRange   = 4.0f;
    flake.velocity        = 40.0f;
    flake.velocityRange   = 20.0f;
    flake.emissionLongitude = M_PI;
    flake.emissionRange   = M_PI / 6.0f;
    flake.xAcceleration   = 8.0f;
    flake.yAcceleration   = 5.0f;
    flake.spin            = 0.2f;
    flake.spinRange       = 0.5f;
    flake.scale           = 0.06f;
    flake.scaleRange      = 0.03f;
    flake.alphaSpeed      = -0.04f;
    flake.color           = [UIColor colorWithWhite:0.9f alpha:0.55f].CGColor;
    flake.contents        = (__bridge id)[self _snowflakeImage].CGImage;

    _emitter.emitterCells = @[flake];
    [self.layer insertSublayer:_emitter atIndex:0];
}

- (void)stopSnow {
    [_emitter removeFromSuperlayer];
    _emitter = nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _emitter.emitterPosition = CGPointMake(self.bounds.size.width / 2.0f, -10);
    _emitter.emitterSize     = CGSizeMake(self.bounds.size.width, 1);
}

- (UIImage *)_snowflakeImage {
    CGFloat sz = 40.0f;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(sz, sz), NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextSetLineWidth(ctx, 2.5f);
    CGFloat cx = sz/2, cy = sz/2, r = sz/2 - 2;
    int arms = 6;
    for (int i = 0; i < arms; i++) {
        CGFloat angle = (M_PI * 2 / arms) * i;
        CGFloat ex = cx + r * cosf(angle);
        CGFloat ey = cy + r * sinf(angle);
        CGContextMoveToPoint(ctx, cx, cy);
        CGContextAddLineToPoint(ctx, ex, ey);
        // Small branches
        for (CGFloat t = 0.4f; t <= 0.8f; t += 0.2f) {
            CGFloat bx = cx + r * t * cosf(angle);
            CGFloat by = cy + r * t * sinf(angle);
            CGFloat bl = r * 0.25f;
            CGContextMoveToPoint(ctx, bx, by);
            CGContextAddLineToPoint(ctx,
                bx + bl * cosf(angle + M_PI/3),
                by + bl * sinf(angle + M_PI/3));
            CGContextMoveToPoint(ctx, bx, by);
            CGContextAddLineToPoint(ctx,
                bx + bl * cosf(angle - M_PI/3),
                by + bl * sinf(angle - M_PI/3));
        }
    }
    CGContextStrokePath(ctx);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}
@end

// ─────────────────────────────────────────────────────────────────────────────
#pragma mark - SidebarButton
// ─────────────────────────────────────────────────────────────────────────────
static CGFloat const kSidebarBtnSz = 46.0f;

@implementation SidebarButton

- (instancetype)initWithTab:(MenuTab)tab sfName:(NSString *)sfName {
    if ((self = [super initWithFrame:CGRectMake(0,0,kSidebarBtnSz,kSidebarBtnSz)])) {
        _tab = tab;
        self.layer.cornerRadius  = kSidebarBtnSz / 2.0f;
        self.layer.masksToBounds = YES;
        self.layer.borderWidth   = 1.5f;
        self.layer.borderColor   = kColorBorder.CGColor;
        self.backgroundColor     = kColorSidebar;

        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration
            configurationWithPointSize:18 weight:UIImageSymbolWeightMedium];
        UIImage *img = [[UIImage systemImageNamed:sfName
                          withConfiguration:cfg]
                        imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self setImage:img forState:UIControlStateNormal];
        self.tintColor = kColorBlueDim;
        [self setActive:NO animated:NO];
    }
    return self;
}

- (void)setActive:(BOOL)active animated:(BOOL)animated {
    _isActive = active;
    void (^changes)(void) = ^{
        if (active) {
            self.backgroundColor = kColorBlueDim;
            self.tintColor       = kColorBlueLight;
            self.layer.borderColor = kColorBlue.CGColor;
        } else {
            self.backgroundColor = kColorSidebar;
            self.tintColor       = [UIColor colorWithWhite:0.45 alpha:1.0];
            self.layer.borderColor = kColorBorder.CGColor;
        }
    };
    if (animated) {
        [UIView animateWithDuration:0.2 animations:changes];
    } else {
        changes();
    }
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(kSidebarBtnSz, kSidebarBtnSz);
}
@end

// ─────────────────────────────────────────────────────────────────────────────
#pragma mark - MenuNavBar
// ─────────────────────────────────────────────────────────────────────────────
@implementation MenuNavBar

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self _setup];
    }
    return self;
}

- (void)_setup {
    self.backgroundColor = [UIColor clearColor];

    // Title pill container
    UIView *titlePill = [[UIView alloc] init];
    titlePill.translatesAutoresizingMaskIntoConstraints = NO;
    titlePill.backgroundColor = kColorBlueDim;
    titlePill.layer.cornerRadius = 12.0f;
    titlePill.layer.masksToBounds = YES;
    titlePill.layer.borderColor = kColorBlue.CGColor;
    titlePill.layer.borderWidth = 1.0f;
    [self addSubview:titlePill];

    _titleIcon = [[UIImageView alloc] init];
    _titleIcon.translatesAutoresizingMaskIntoConstraints = NO;
    _titleIcon.tintColor = kColorBlueLight;
    _titleIcon.contentMode = UIViewContentModeScaleAspectFit;
    [titlePill addSubview:_titleIcon];

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.textColor = kColorBlueLight;
    _titleLabel.font = [UIFont systemFontOfSize:16.0f weight:UIFontWeightBold];
    _titleLabel.text = @"UI";
    [titlePill addSubview:_titleLabel];

    // Action buttons
    _saveButton  = [self _makeIconButtonName:@"arrow.down.to.line" size:17];
    _moonButton  = [self _makeIconButtonName:@"moon.fill"           size:16];
    _closeButton = [self _makeIconButtonName:@"xmark"               size:16];

    [self addSubview:_saveButton];
    [self addSubview:_moonButton];
    [self addSubview:_closeButton];

    [NSLayoutConstraint activateConstraints:@[
        // Title pill
        [titlePill.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:2],
        [titlePill.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [titlePill.heightAnchor constraintEqualToConstant:38],

        // Icon + label inside pill
        [_titleIcon.leadingAnchor constraintEqualToAnchor:titlePill.leadingAnchor constant:10],
        [_titleIcon.centerYAnchor constraintEqualToAnchor:titlePill.centerYAnchor],
        [_titleIcon.widthAnchor constraintEqualToConstant:18],
        [_titleIcon.heightAnchor constraintEqualToConstant:18],
        [_titleLabel.leadingAnchor constraintEqualToAnchor:_titleIcon.trailingAnchor constant:6],
        [_titleLabel.centerYAnchor constraintEqualToAnchor:titlePill.centerYAnchor],
        [_titleLabel.trailingAnchor constraintEqualToAnchor:titlePill.trailingAnchor constant:-12],

        // Action buttons
        [_closeButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-2],
        [_closeButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [_moonButton.trailingAnchor constraintEqualToAnchor:_closeButton.leadingAnchor constant:-6],
        [_moonButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [_saveButton.trailingAnchor constraintEqualToAnchor:_moonButton.leadingAnchor constant:-6],
        [_saveButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    ]];
}

- (UIButton *)_makeIconButtonName:(NSString *)name size:(CGFloat)ptSize {
    UIButton *btn = [[UIButton alloc] init];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    btn.backgroundColor = kColorRow;
    btn.layer.cornerRadius = 14;
    btn.layer.masksToBounds = YES;
    btn.layer.borderColor = kColorBorder.CGColor;
    btn.layer.borderWidth = 0.5f;

    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration
        configurationWithPointSize:ptSize weight:UIImageSymbolWeightMedium];
    UIImage *img = [[UIImage systemImageNamed:name withConfiguration:cfg]
                    imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [btn setImage:img forState:UIControlStateNormal];
    btn.tintColor = [UIColor colorWithWhite:0.75 alpha:1.0];

    [NSLayoutConstraint activateConstraints:@[
        [btn.widthAnchor constraintEqualToConstant:36],
        [btn.heightAnchor constraintEqualToConstant:36],
    ]];
    return btn;
}

- (void)setTabTitle:(NSString *)title iconName:(NSString *)sfName {
    _titleLabel.text = title;
    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration
        configurationWithPointSize:16 weight:UIImageSymbolWeightMedium];
    _titleIcon.image = [[UIImage systemImageNamed:sfName withConfiguration:cfg]
                        imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}
@end

// ─────────────────────────────────────────────────────────────────────────────
#pragma mark - MenuContentView
// ─────────────────────────────────────────────────────────────────────────────
@interface MenuContentView ()
@property (nonatomic, strong) UIScrollView             *scroll;
@property (nonatomic, strong) UIStackView              *stack;
@property (nonatomic, strong) NSArray<ToggleItem *>    *items;
@end

@implementation MenuContentView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self _setup];
    }
    return self;
}

- (void)_setup {
    self.backgroundColor = [UIColor clearColor];

    _scroll = [[UIScrollView alloc] init];
    _scroll.translatesAutoresizingMaskIntoConstraints = NO;
    _scroll.showsVerticalScrollIndicator   = YES;
    _scroll.showsHorizontalScrollIndicator = NO;
    _scroll.backgroundColor = [UIColor clearColor];
    [self addSubview:_scroll];

    _stack = [[UIStackView alloc] init];
    _stack.translatesAutoresizingMaskIntoConstraints = NO;
    _stack.axis    = UILayoutConstraintAxisVertical;
    _stack.spacing = 8.0f;
    [_scroll addSubview:_stack];

    [NSLayoutConstraint activateConstraints:@[
        [_scroll.topAnchor constraintEqualToAnchor:self.topAnchor],
        [_scroll.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [_scroll.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_scroll.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],

        [_stack.topAnchor constraintEqualToAnchor:_scroll.topAnchor constant:4],
        [_stack.bottomAnchor constraintEqualToAnchor:_scroll.bottomAnchor constant:-4],
        [_stack.leadingAnchor constraintEqualToAnchor:_scroll.leadingAnchor],
        [_stack.trailingAnchor constraintEqualToAnchor:_scroll.trailingAnchor],
        [_stack.widthAnchor constraintEqualToAnchor:_scroll.widthAnchor],
    ]];
}

- (void)loadItems:(NSArray<ToggleItem *> *)items {
    _items = items;
    [self reloadData];
}

- (void)reloadData {
    for (UIView *v in _stack.arrangedSubviews) {
        [_stack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    for (ToggleItem *item in _items) {
        ToggleRowView *row = [[ToggleRowView alloc] initWithItem:item];
        row.translatesAutoresizingMaskIntoConstraints = NO;
        [_stack addArrangedSubview:row];
    }
}
@end

// ─────────────────────────────────────────────────────────────────────────────
#pragma mark - Profile info rows
// ─────────────────────────────────────────────────────────────────────────────
@interface ProfileInfoView : UIView
- (instancetype)initWithRows:(NSArray<NSDictionary *> *)rows;
@end

@implementation ProfileInfoView

- (instancetype)initWithRows:(NSArray<NSDictionary *> *)rows {
    if ((self = [super initWithFrame:CGRectZero])) {
        UIStackView *stack = [[UIStackView alloc] init];
        stack.translatesAutoresizingMaskIntoConstraints = NO;
        stack.axis    = UILayoutConstraintAxisVertical;
        stack.spacing = 0;
        [self addSubview:stack];
        [NSLayoutConstraint activateConstraints:@[
            [stack.topAnchor constraintEqualToAnchor:self.topAnchor],
            [stack.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            [stack.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [stack.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        ]];

        for (NSDictionary *row in rows) {
            UIView *rowView = [[UIView alloc] init];
            rowView.backgroundColor = [UIColor clearColor];

            UILabel *key = [[UILabel alloc] init];
            key.translatesAutoresizingMaskIntoConstraints = NO;
            key.text      = row[@"key"];
            key.textColor = kColorSubtext;
            key.font      = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];

            UILabel *val = [[UILabel alloc] init];
            val.translatesAutoresizingMaskIntoConstraints = NO;
            val.text = row[@"value"];
            UIColor *valColor = kColorText;
            if ([row[@"color"] isEqualToString:@"green"])  valColor = [UIColor colorWithRed:0.18 green:0.85 blue:0.40 alpha:1.0];
            if ([row[@"color"] isEqualToString:@"blue"])   valColor = kColorBlueLight;
            if ([row[@"color"] isEqualToString:@"orange"]) valColor = kColorOrange;
            val.textColor = valColor;
            val.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];

            [rowView addSubview:key];
            [rowView addSubview:val];
            [NSLayoutConstraint activateConstraints:@[
                [key.leadingAnchor constraintEqualToAnchor:rowView.leadingAnchor constant:16],
                [key.centerYAnchor constraintEqualToAnchor:rowView.centerYAnchor],
                [key.widthAnchor constraintEqualToConstant:90],
                [val.leadingAnchor constraintEqualToAnchor:key.trailingAnchor constant:4],
                [val.centerYAnchor constraintEqualToAnchor:rowView.centerYAnchor],
                [rowView.heightAnchor constraintEqualToConstant:36],
            ]];

            // Separator line
            UIView *sep = [[UIView alloc] init];
            sep.backgroundColor = kColorBorder;
            sep.translatesAutoresizingMaskIntoConstraints = NO;

            UIView *container = [[UIView alloc] init];
            container.backgroundColor = kColorRow;
            [container addSubview:rowView];
            [container addSubview:sep];
            rowView.translatesAutoresizingMaskIntoConstraints = NO;
            [NSLayoutConstraint activateConstraints:@[
                [rowView.topAnchor constraintEqualToAnchor:container.topAnchor],
                [rowView.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
                [rowView.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
                [sep.topAnchor constraintEqualToAnchor:rowView.bottomAnchor],
                [sep.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:16],
                [sep.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
                [sep.heightAnchor constraintEqualToConstant:0.5f],
                [container.bottomAnchor constraintEqualToAnchor:sep.bottomAnchor],
            ]];
            [stack addArrangedSubview:container];
        }

        // Round top and bottom corners only
        if (rows.count > 0) {
            UIView *first = stack.arrangedSubviews.firstObject;
            UIView *last  = stack.arrangedSubviews.lastObject;
            first.layer.cornerRadius = 14;
            first.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
            first.layer.masksToBounds = YES;
            last.layer.cornerRadius  = 14;
            last.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
            last.layer.masksToBounds = YES;
        }
    }
    return self;
}
@end

// ─────────────────────────────────────────────────────────────────────────────
#pragma mark - MenuViewController
// ─────────────────────────────────────────────────────────────────────────────

// Tab data
static NSString *kTabNames[] = { @"UI", @"AIMBOT", @"GAMEPAD", @"TOOLS", @"PROFILE" };
static NSString *kTabIcons[] = {
    @"square.grid.2x2.fill",
    @"scope",
    @"gamecontroller.fill",
    @"wrench.and.screwdriver.fill",
    @"person.fill"
};

@implementation MenuViewController {
    UIView      *_profileView;
    CGPoint      _dragStart;
    CGPoint      _panelOrigin;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    [self _buildLayout];
    [self switchToTab:MenuTabUI animated:NO];
}

- (void)_buildLayout {
    CGRect f = self.view.bounds;

    // Snowfall
    _snowView = [[SnowfallView alloc] initWithFrame:f];
    _snowView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _snowView.userInteractionEnabled = NO;
    [self.view addSubview:_snowView];

    // ── Sidebar ──────────────────────────────────────────────────────────────
    _sidebarView = [[UIView alloc] init];
    _sidebarView.translatesAutoresizingMaskIntoConstraints = NO;
    _sidebarView.backgroundColor = kColorSidebar;
    _sidebarView.layer.cornerRadius = 22;
    _sidebarView.layer.masksToBounds = YES;
    _sidebarView.layer.borderColor = kColorBorder.CGColor;
    _sidebarView.layer.borderWidth = 0.5f;
    [self.view addSubview:_sidebarView];

    UIStackView *sideStack = [[UIStackView alloc] init];
    sideStack.translatesAutoresizingMaskIntoConstraints = NO;
    sideStack.axis    = UILayoutConstraintAxisVertical;
    sideStack.spacing = 10.0f;
    [_sidebarView addSubview:sideStack];

    NSMutableArray *btns = [NSMutableArray array];
    for (NSInteger i = 0; i < 5; i++) {
        SidebarButton *btn = [[SidebarButton alloc]
            initWithTab:(MenuTab)i sfName:kTabIcons[i]];
        btn.translatesAutoresizingMaskIntoConstraints = NO;
        [btn addTarget:self action:@selector(_sidebarTapped:)
            forControlEvents:UIControlEventTouchUpInside];
        [sideStack addArrangedSubview:btn];
        [btns addObject:btn];
        [NSLayoutConstraint activateConstraints:@[
            [btn.widthAnchor constraintEqualToConstant:kSidebarBtnSz],
            [btn.heightAnchor constraintEqualToConstant:kSidebarBtnSz],
        ]];
    }
    _sidebarButtons = [btns copy];

    [NSLayoutConstraint activateConstraints:@[
        [_sidebarView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [_sidebarView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:120],
        [_sidebarView.widthAnchor constraintEqualToConstant:kSidebarBtnSz + 14],
        [sideStack.centerXAnchor constraintEqualToAnchor:_sidebarView.centerXAnchor],
        [sideStack.topAnchor constraintEqualToAnchor:_sidebarView.topAnchor constant:10],
        [sideStack.bottomAnchor constraintEqualToAnchor:_sidebarView.bottomAnchor constant:-10],
    ]];

    // ── Main panel ───────────────────────────────────────────────────────────
    _panelView = [[UIView alloc] init];
    _panelView.translatesAutoresizingMaskIntoConstraints = NO;
    _panelView.backgroundColor = kColorPanel;
    _panelView.layer.cornerRadius  = 18.0f;
    _panelView.layer.masksToBounds = YES;
    _panelView.layer.borderColor   = kColorBorder.CGColor;
    _panelView.layer.borderWidth   = 0.5f;
    [self.view addSubview:_panelView];

    // Gradient overlay for depth
    CAGradientLayer *grad = [CAGradientLayer layer];
    grad.frame  = CGRectMake(0, 0, 300, 500);
    grad.colors = @[
        (id)[UIColor colorWithRed:0.16 green:0.22 blue:0.35 alpha:0.5].CGColor,
        (id)[UIColor colorWithRed:0.09 green:0.13 blue:0.21 alpha:0.5].CGColor,
    ];
    grad.locations = @[@0.0, @1.0];
    [_panelView.layer insertSublayer:grad atIndex:0];

    _navBar = [[MenuNavBar alloc] init];
    _navBar.translatesAutoresizingMaskIntoConstraints = NO;
    [_panelView addSubview:_navBar];
    [_navBar.closeButton addTarget:self action:@selector(_closeTapped)
                  forControlEvents:UIControlEventTouchUpInside];

    _contentView = [[MenuContentView alloc] init];
    _contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [_panelView addSubview:_contentView];

    _profileView = [[UIView alloc] init];
    _profileView.translatesAutoresizingMaskIntoConstraints = NO;
    _profileView.backgroundColor = [UIColor clearColor];
    _profileView.hidden = YES;
    [_panelView addSubview:_profileView];

    [NSLayoutConstraint activateConstraints:@[
        [_panelView.leadingAnchor constraintEqualToAnchor:_sidebarView.trailingAnchor constant:8],
        [_panelView.topAnchor constraintEqualToAnchor:_sidebarView.topAnchor],
        [_panelView.widthAnchor constraintEqualToConstant:300],
        [_panelView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-120],

        [_navBar.topAnchor constraintEqualToAnchor:_panelView.topAnchor constant:10],
        [_navBar.leadingAnchor constraintEqualToAnchor:_panelView.leadingAnchor constant:12],
        [_navBar.trailingAnchor constraintEqualToAnchor:_panelView.trailingAnchor constant:-12],
        [_navBar.heightAnchor constraintEqualToConstant:44],

        [_contentView.topAnchor constraintEqualToAnchor:_navBar.bottomAnchor constant:10],
        [_contentView.leadingAnchor constraintEqualToAnchor:_panelView.leadingAnchor constant:10],
        [_contentView.trailingAnchor constraintEqualToAnchor:_panelView.trailingAnchor constant:-10],
        [_contentView.bottomAnchor constraintEqualToAnchor:_panelView.bottomAnchor constant:-10],

        [_profileView.topAnchor constraintEqualToAnchor:_navBar.bottomAnchor constant:10],
        [_profileView.leadingAnchor constraintEqualToAnchor:_panelView.leadingAnchor constant:10],
        [_profileView.trailingAnchor constraintEqualToAnchor:_panelView.trailingAnchor constant:-10],
        [_profileView.bottomAnchor constraintEqualToAnchor:_panelView.bottomAnchor constant:-10],
    ]];

    // Drag gesture
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(_panGesture:)];
    [_panelView addGestureRecognizer:pan];
}

- (void)_panGesture:(UIPanGestureRecognizer *)pan {
    CGPoint trans = [pan translationInView:self.view];
    if (pan.state == UIGestureRecognizerStateBegan) {
        _panelOrigin = _panelView.frame.origin;
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        CGRect fr = _panelView.frame;
        fr.origin.x = _panelOrigin.x + trans.x;
        fr.origin.y = _panelOrigin.y + trans.y;
        // Clamp within screen
        CGRect screen = self.view.bounds;
        fr.origin.x = MAX(0, MIN(fr.origin.x, screen.size.width - fr.size.width));
        fr.origin.y = MAX(0, MIN(fr.origin.y, screen.size.height - fr.size.height));
        _panelView.frame = fr;

        // Move sidebar alongside
        CGRect sf = _sidebarView.frame;
        sf.origin.x = fr.origin.x - sf.size.width - 8;
        sf.origin.y = fr.origin.y;
        sf.origin.x = MAX(0, sf.origin.x);
        _sidebarView.frame = sf;
    }
}

- (void)_sidebarTapped:(SidebarButton *)btn {
    [self switchToTab:btn.tab animated:YES];
}

- (void)switchToTab:(MenuTab)tab animated:(BOOL)animated {
    _currentTab = tab;
    for (SidebarButton *b in _sidebarButtons) {
        [b setActive:(b.tab == tab) animated:animated];
    }
    [_navBar setTabTitle:kTabNames[tab]
               iconName:kTabIcons[tab]];

    void (^update)(void) = ^{
        if (tab == MenuTabProfile) {
            self->_contentView.hidden = YES;
            self->_profileView.hidden = NO;
            [self _buildProfileView];
        } else {
            self->_contentView.hidden = NO;
            self->_profileView.hidden = YES;
            [self->_contentView loadItems:[self _itemsForTab:tab]];
        }
    };

    if (animated) {
        [UIView transitionWithView:_panelView
                          duration:0.22
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:update
                        completion:nil];
    } else {
        update();
    }
}

- (NSArray<ToggleItem *> *)_itemsForTab:(MenuTab)tab {
    switch (tab) {
        case MenuTabUI:
            return @[
                [ToggleItem itemTitle:@"Show Ghost UI"
                             subtitle:nil warning:nil key:@"showGhostUI"         isOn:NO],
                [ToggleItem itemTitle:@"Show TeleVIP UI"
                             subtitle:nil warning:nil key:@"showTeleVIPUI"       isOn:YES],
                [ToggleItem itemTitle:@"Show Underground UI"
                             subtitle:nil warning:nil key:@"showUndergroundUI"   isOn:NO],
                [ToggleItem itemTitle:@"Show AI Telekill UI"
                             subtitle:nil warning:nil key:@"showAITelekillUI"    isOn:NO],
            ];
        case MenuTabAimbot:
            return @[
                [ToggleItem itemTitle:@"Enable Aimbot"
                             subtitle:nil warning:nil key:@"enableAimbot"        isOn:YES],
                [ToggleItem itemTitle:@"Aimsilent"
                             subtitle:@"Hides aimbot from killcam and replays"
                              warning:nil key:@"aimsilent"                       isOn:YES],
                [ToggleItem itemTitle:@"Aim Kill"
                             subtitle:@"Automatically kills enemies when aiming at them"
                              warning:@"To turn on Aim Kill fast, select HEADv2 below"
                                  key:@"aimKill"                                isOn:NO],
                [ToggleItem itemTitle:@"AutoFire"
                             subtitle:nil warning:nil key:@"autoFire"            isOn:NO],
            ];
        case MenuTabGamepad:
            return @[
                [ToggleItem itemTitle:@"Custom Sensitivity"
                             subtitle:nil warning:nil key:@"customSensitivity"   isOn:NO],
                [ToggleItem itemTitle:@"Rapid Fire"
                             subtitle:nil warning:nil key:@"rapidFire"           isOn:NO],
                [ToggleItem itemTitle:@"Auto Reload"
                             subtitle:nil warning:nil key:@"autoReload"          isOn:YES],
            ];
        case MenuTabTools:
            return @[
                [ToggleItem itemTitle:@"Bypass Detection"
                             subtitle:nil warning:nil key:@"bypassDetect"        isOn:NO],
                [ToggleItem itemTitle:@"Anti-Ban"
                             subtitle:@"Reduces ban probability"
                              warning:nil key:@"antiBan"                         isOn:YES],
                [ToggleItem itemTitle:@"Speed Hack"
                             subtitle:nil warning:nil key:@"speedHack"           isOn:NO],
            ];
        default: return @[];
    }
}

- (void)_buildProfileView {
    for (UIView *v in _profileView.subviews) [v removeFromSuperview];

    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"HH:mm:ss";
    NSString *timeStr = [fmt stringFromDate:[NSDate date]];

    NSArray *rows = @[
        @{ @"key": @"FPS",         @"value": @"0",         @"color": @"green"  },
        @{ @"key": @"Time",        @"value": timeStr,      @"color": @"blue"   },
        @{ @"key": @"Device",      @"value": @"iPhone",    @"color": @"white"  },
        @{ @"key": @"iOS",         @"value": @"16.7.12",   @"color": @"white"  },
        @{ @"key": @"Name",        @"value": @"iPhone",    @"color": @"white"  },
        @{ @"key": @"Version",     @"value": @"1.118.1",   @"color": @"orange" },
        @{ @"key": @"License Key", @"value": @"Not Available", @"color": @"white" },
    ];

    ProfileInfoView *piv = [[ProfileInfoView alloc] initWithRows:rows];
    piv.translatesAutoresizingMaskIntoConstraints = NO;
    [_profileView addSubview:piv];
    [NSLayoutConstraint activateConstraints:@[
        [piv.topAnchor constraintEqualToAnchor:_profileView.topAnchor],
        [piv.leadingAnchor constraintEqualToAnchor:_profileView.leadingAnchor],
        [piv.trailingAnchor constraintEqualToAnchor:_profileView.trailingAnchor],
    ]];
}

- (void)_closeTapped {
    [[MenuWindow sharedMenu] hide];
}
@end

// ─────────────────────────────────────────────────────────────────────────────
#pragma mark - MenuWindow
// ─────────────────────────────────────────────────────────────────────────────
static MenuWindow *_sharedMenu = nil;

@implementation MenuWindow

+ (instancetype)sharedMenu {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _sharedMenu = [[MenuWindow alloc] initMenuWindow];
    });
    return _sharedMenu;
}

- (instancetype)initMenuWindow {
    UIWindowScene *scene = nil;
    for (UIScene *s in [UIApplication sharedApplication].connectedScenes) {
        if ([s isKindOfClass:[UIWindowScene class]]) {
            scene = (UIWindowScene *)s;
            break;
        }
    }
    if ((self = scene
            ? [super initWithWindowScene:scene]
            : [super initWithFrame:[UIScreen mainScreen].bounds])) {
        self.windowLevel         = UIWindowLevelAlert + 100;
        self.backgroundColor     = [UIColor clearColor];
        self.rootViewController  = [[MenuViewController alloc] init];
        self.hidden              = YES;
        self.layer.cornerRadius  = 0;
    }
    return self;
}

- (void)show {
    _menuVisible = YES;
    self.hidden  = NO;
    self.alpha   = 0;
    self.rootViewController.view.transform = CGAffineTransformMakeScale(0.9, 0.9);
    [UIView animateWithDuration:0.28
                          delay:0
         usingSpringWithDamping:0.8
          initialSpringVelocity:0.4
                        options:0
                     animations:^{
        self.alpha = 1;
        self.rootViewController.view.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)hide {
    _menuVisible = NO;
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 0;
        self.rootViewController.view.transform = CGAffineTransformMakeScale(0.9, 0.9);
    } completion:^(BOOL done) {
        self.hidden = YES;
        self.rootViewController.view.transform = CGAffineTransformIdentity;
    }];
}

- (void)toggle {
    _menuVisible ? [self hide] : [self show];
}
@end
