//
//  AWSSAMLSignInProvider.m
//  AWSSamlSignIn
//
// Copyright 2016 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to
// copy, distribute and modify it.
//

#import "AWSSAMLSignInProvider.h"
#import "AWSSignInManager.h"
#import <AWSCore/AWSUICKeyChainStore.h>

static NSString *const AWSSAMLSignInProviderUserNameKeySuffix = @"SAML.userName";
static NSString *const AWSSAMLSignInProviderImageURLKeySuffix = @"SAML.imageURL";
static NSString *const AWSSAMLSignInProviderTokenSuffix = @"SAML.loginToken";

typedef void (^AWSSignInManagerCompletionBlock)(id result, AWSAuthState authState, NSError *error);

@interface AWSSignInManager()

- (void)completeLogin;

@end

@interface AWSSAMLSignInProvider()

@property (strong, nonatomic) NSString *uniqueIdentfier;
@property (strong, nonatomic) NSString *samlIdentityProviderName;
@property (nonatomic, strong) AWSUICKeyChainStore *keychain;
@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSURL *imageURL;
@property (atomic, copy) AWSSignInManagerCompletionBlock completionHandler;
@property (nonatomic, strong) UIViewController *signInViewController;

@end

@implementation AWSSAMLSignInProvider

- (instancetype)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"`- init` is not a valid initializer. This class is to be used as an abstract base class for SAML sign in provider."
                                 userInfo:nil];
    return nil;
}

- (instancetype)initWithIdentifier:(NSString *)uniqueIdentifier
              identityProviderName:(NSString *)identityProviderName {
    if (self = [super init]) {
        if (!uniqueIdentifier || [uniqueIdentifier length] == 0) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:@"The value of `uniqueIdentifier` cannot be `nil` or empty string."
                                         userInfo:nil];
        }
        _uniqueIdentfier = uniqueIdentifier;
        _samlIdentityProviderName = identityProviderName;
        _keychain = [AWSUICKeyChainStore keyChainStoreWithService:[NSString stringWithFormat:@"SAML.%@", _uniqueIdentfier]];
        _signInViewController = nil;
    }
    
    return self;
}

#pragma mark - AWSIdentityProvider

- (NSString *)identityProviderName {
    return self.samlIdentityProviderName;
}

- (AWSTask<NSString *> *)token {
    return [self fetchLatestToken];
}

#pragma mark - Instance Methods

- (BOOL)isLoggedIn {
    return [self fetchStoredToken];
}

- (void)reloadSession {
    if ([self isLoggedIn]) {
        [[self fetchLatestToken] continueWithBlock:^id _Nullable(AWSTask<NSString *> * _Nonnull task) {
            if (task.result) {
                [self completeLogin];
            } else if (task.error) {
                AWSLogError(@"Could not reload the session. Refreshed token missing.");
            }
            return nil;
        }];
    }
}

- (void)completeLogin {
    [[AWSSignInManager sharedInstance] completeLogin];
}

- (void)saveToken:(NSString *)token {
    self.keychain[[self stringWithUniqueIdentifierPrefix:AWSSAMLSignInProviderTokenSuffix]] = token;
}

- (void)deleteToken {
    [self.keychain removeItemForKey:[self stringWithUniqueIdentifierPrefix:AWSSAMLSignInProviderTokenSuffix]];
}

- (NSString *)fetchStoredToken {
    return self.keychain[[self stringWithUniqueIdentifierPrefix:AWSSAMLSignInProviderTokenSuffix]];
}

- (void)login:(AWSSignInManagerCompletionBlock)completionHandler {
    self.completionHandler = completionHandler;
    AWSTaskCompletionSource<NSString *> *taskCompletionSource = [AWSTaskCompletionSource taskCompletionSource];
    
    [self handleLoginWithTaskCompletionSource:taskCompletionSource];
    [taskCompletionSource.task continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
        AWSAuthState authState = [AWSSignInManager sharedInstance].authState;
        if(task.error){
            self.completionHandler(nil, authState, task.error);
        } else {
            [self completeLoginWithToken:task.result];
        }
        return nil;
    }];
}

- (void)completeLoginWithToken:(NSString *)token {
    [self saveToken:token];
    [self completeLogin];
}

- (void)cancelLoginWithError:(NSError *)error {
    AWSAuthState authState = [AWSSignInManager sharedInstance].authState;
    self.completionHandler(nil, authState, error);
}

- (void)logout {
    [self deleteToken];
}

- (void)setViewControllerForSignIn:(UIViewController *)signInViewController {
    self.signInViewController = signInViewController;
}

- (UIViewController *)getViewControllerForSignIn {
    return self.signInViewController;
}

#pragma mark - Mandatory Override Methods

- (void)handleLoginWithTaskCompletionSource:(AWSTaskCompletionSource<NSString *> *)taskCompletionSource {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"`-handleLoginWithTaskCompletionSource` cannot be called for the base `AWSSAMLSignInProvider` class. This method has to be over-ridden in the class extending AWSSAMLSignInProvider."
                                 userInfo:nil];
}

- (AWSTask<NSString *>*)fetchLatestToken {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"`-fetchLatestToken` cannot be called for the base `AWSSAMLSignInProvider` class. This method has to be over-ridden in the class extending AWSSAMLSignInProvider."
                                 userInfo:nil];
    return nil;
}

#pragma mark - Optional Override Methods

- (BOOL)interceptApplication:(UIApplication *)application
                     openURL:(NSURL *)url
           sourceApplication:(nullable NSString *)sourceApplication
                  annotation:(id)annotation {
    return YES;
}

- (BOOL)interceptApplication:(UIApplication *)application
didFinishLaunchingWithOptions:(nullable NSDictionary *)launchOptions {
    return YES;
}

#pragma mark - Helper Method

- (NSString *)stringWithUniqueIdentifierPrefix:(NSString *)suffix {
    return [self.uniqueIdentfier stringByAppendingString: [NSString stringWithFormat:@".%@", suffix]];
}

@end
