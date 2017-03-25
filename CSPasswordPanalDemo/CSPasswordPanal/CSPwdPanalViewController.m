//
//  CSPwdPanalViewController.m
//  CSPasswordPanal
//
//  Created by Joslyn Wu on 20/03/2017.
//  Copyright © 2017 joslyn. All rights reserved.
//

#import "CSPwdPanalViewController.h"
#import "UIColor+Hex.h"
#import <Masonry.h>

#define ZAI_RGBA(r,g,b,a)   [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:a]
static const NSInteger pwdNumCount = 6;
static const CGFloat passwordTextFieldWidth = 238;
static const CGFloat passwordTextFieldHeight = 44;
static const CGFloat passwordPanalMaxY = 391;

@interface CSPwdPanalViewController ()

@property (nonatomic, strong) UITextField *pwdTextField;
@property (nonatomic, strong) NSMutableArray *pwdViews;
@property (nonatomic, strong) NSString *pwdString;
@property (nonatomic, strong) UIButton *nextStepBtn;
@property (nonatomic, strong) UIView *panalView;

@end

@implementation CSPwdPanalViewController

#pragma mark  -  public
+ (void)showPasswordPanalWithEntry:(UIViewController *)entyVc confirmComplete:(void(^)(NSString *))confirmBlock forgetPwdBlock:(void(^)())forgetPwdBlock {
    CSPwdPanalViewController *vc = [CSPwdPanalViewController new];
    vc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [entyVc presentViewController:vc animated:NO completion:nil];
    
    vc.confirmBlock = confirmBlock;
    vc.forgetPwdBlock = forgetPwdBlock;
}

#pragma mark  -  lifecycle
-(void)dealloc{
    _pwdTextField.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addNotification];
    
    self.pwdString = @"";
    [self initUI];
    [self.pwdTextField becomeFirstResponder];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyBoard)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
}

- (void)initUI {
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    
    UIView *panalView = [[UIView alloc] init];
    panalView.backgroundColor = ZAI_RGBA(255, 255, 255, 0.9);
    panalView.layer.cornerRadius = 13;
    panalView.clipsToBounds = YES;
    self.panalView = panalView;
    [self.view addSubview:panalView];
    
    [panalView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(270);
        make.height.mas_equalTo(220);
        make.topMargin.mas_equalTo(passwordPanalMaxY - 220);
        make.centerX.mas_equalTo(self.view);
    }];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"输入交易密码";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont boldSystemFontOfSize:17];
    titleLabel.textColor = ZAI_RGBA(70, 70, 70, 1);
    [panalView addSubview:titleLabel];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.topMargin.mas_equalTo(17.5);
        make.centerX.mas_equalTo(panalView);
        make.width.mas_equalTo(120);
        make.height.mas_equalTo(24);
    }];
    
    UIButton *cancelBtn = [[UIButton alloc] init];
    [cancelBtn setImage:[UIImage imageNamed:@"login_delete"] forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(close:) forControlEvents:UIControlEventTouchUpInside];
    [panalView addSubview:cancelBtn];
    [cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.width.mas_equalTo(27);
        make.centerY.mas_equalTo(titleLabel);
        make.trailingMargin.mas_equalTo(-19.5);
    }];
    
    
    [panalView addSubview:self.pwdTextField];
    [self.pwdTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.topMargin.mas_equalTo(63);
        make.centerX.mas_equalTo(panalView);
        make.height.mas_equalTo(passwordTextFieldHeight);
        make.width.mas_equalTo(passwordTextFieldWidth);
    }];
    
    UIButton *forgetBtn = [[UIButton alloc] init];
    [forgetBtn setTitle:@"忘记密码" forState:UIControlStateNormal];
    forgetBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    [forgetBtn addTarget:self action:@selector(forgetPwdBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [forgetBtn setTitleColor:[UIColor colorWithHexString:@"909090"] forState:UIControlStateNormal];
    [panalView addSubview:forgetBtn];
    [forgetBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.pwdTextField.mas_bottom).offset(10);
        make.trailing.mas_equalTo(self.pwdTextField);
    }];
    
    UIButton *confirmBtn = [[UIButton alloc] init];
    self.nextStepBtn = confirmBtn;
    confirmBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [confirmBtn setTitle:@"确认" forState:UIControlStateNormal];
    [confirmBtn addTarget:self action:@selector(nextStepBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [confirmBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    confirmBtn.layer.cornerRadius = 4;
    confirmBtn.clipsToBounds = YES;
    [self setNextStepBtnEnabled:NO];
    [panalView addSubview:self.nextStepBtn];
    [self.nextStepBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(panalView);
        make.bottomMargin.mas_equalTo(-20);
        make.width.mas_equalTo(238);
        make.height.mas_equalTo(44);
    }];
    
    
    CGFloat gridWidth = passwordTextFieldWidth / pwdNumCount;
    for (NSInteger i = 1; i < pwdNumCount; i++) {
        CGFloat gridTop = 9;
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(i * gridWidth, gridTop, 1.f, passwordTextFieldHeight - gridTop * 2)];
        lineView.backgroundColor = [UIColor colorWithHexString:@"e6e6e6"];
        [self.pwdTextField addSubview:lineView];
    }
    
}

#pragma mark  -  action
- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardChange:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardChange:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldChanged:) name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)addOnePwd {
    CGFloat viewW = 6.f;
    NSInteger count = self.pwdViews.count;
    CGFloat everyWidth = passwordTextFieldWidth / pwdNumCount;
    CGFloat left = (everyWidth - viewW) / 2 + count * everyWidth;
    
    UIView *pwdView = [[UIView alloc] init];
    [self.pwdTextField addSubview:pwdView];
    pwdView.backgroundColor = [UIColor colorWithHexString:@"464646"];
    pwdView.layer.cornerRadius = viewW / 2;
    pwdView.layer.masksToBounds = YES;
    [pwdView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(viewW, viewW));
        make.left.equalTo(self.pwdTextField).offset(left);
        make.centerY.equalTo(self.pwdTextField);
    }];
    
    [self.pwdViews addObject:pwdView];
    
    NSString *noSpaceText = [self.pwdTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    self.pwdString = [NSString stringWithFormat:@"%@%@", self.pwdString, noSpaceText];
}

- (void)setNextStepBtnEnabled:(BOOL)enabled {
    if (enabled) {
        self.nextStepBtn.backgroundColor = [UIColor colorWithHexString:@"12c286"];
        self.nextStepBtn.enabled = YES;
    } else {
        self.nextStepBtn.backgroundColor = [UIColor colorWithHexString:@"909090"];
        self.nextStepBtn.enabled = NO;
    }
}

#pragma mark  -  listen
- (void)textFieldChanged:(NSNotification *)ntf {
    if ([self.pwdTextField.text isEqualToString:@""]) { // delete char
        NSInteger index = self.pwdViews.count - 1;
        if (index >= 0) {
            UIView *pwdView = self.pwdViews[index];
            [pwdView removeFromSuperview];
            [self.pwdViews removeLastObject];
            pwdView = nil;
            
            self.pwdString = [self.pwdString substringToIndex:self.pwdString.length - 1];
        }
        
    } else {
        if (self.pwdViews.count < pwdNumCount) {
            [self addOnePwd];
        }
    }
    
    if (self.pwdViews.count == pwdNumCount) {
        [self setNextStepBtnEnabled:YES];
    } else {
        [self setNextStepBtnEnabled:NO];
    }
    
    self.pwdTextField.text = @" "; // the space for delete
}

- (void)keyboardChange:(NSNotification *)ntf {
    CGFloat centerX = [UIScreen mainScreen].bounds.size.width * 0.5;
    CGFloat centerY = [UIScreen mainScreen].bounds.size.height * 0.5;
    if ([ntf.name isEqualToString:@"UIKeyboardWillHideNotification"]) {
        self.view.layer.position = CGPointMake(centerX, centerY);
        return;
    }
    CGRect kbFrame = [ntf.userInfo[@"UIKeyboardFrameEndUserInfoKey"] CGRectValue];
    CGFloat move = kbFrame.origin.y - (passwordPanalMaxY);
    if (move > 0) { return; }
    self.view.layer.position = CGPointMake(centerX, centerY - (-move + 30));
}

- (void)hideKeyBoard {
    [self.view endEditing:YES];
}

- (void)nextStepBtnClicked:(UIButton *)sender {
    if (sender.enabled) {
        if (self.confirmBlock) { self.confirmBlock(self.pwdString); }
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

- (void)forgetPwdBtnClicked:(UIButton *)sender {
    if (self.forgetPwdBlock) {
        self.forgetPwdBlock();
    }
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)close:(UIButton *)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark  -  setter / getter
- (UITextField *)pwdTextField{
    if (!_pwdTextField) {
        _pwdTextField = [[UITextField alloc] init];
        _pwdTextField.backgroundColor = [UIColor whiteColor];
        _pwdTextField.layer.borderWidth = 1.f;
        _pwdTextField.layer.borderColor = [UIColor colorWithHexString:@"e6e6e6"].CGColor;
        _pwdTextField.keyboardType = UIKeyboardTypeNumberPad;
        _pwdTextField.tintColor = [UIColor whiteColor];
    }
    return _pwdTextField;
}

- (NSMutableArray *)pwdViews {
    if (!_pwdViews) {
        _pwdViews = [NSMutableArray array];
    }
    return _pwdViews;
}


@end