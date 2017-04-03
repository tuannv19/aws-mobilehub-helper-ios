//
//  AWSSignInManager.m
//  AWSMobileHubHelper
//
// Copyright 2016 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to
// copy, distribute and modify it.
//

#import "AWSSignInManager.h"
#import "AWSIdentityManager.h"
#import "AWSSignInProviderApplicationIntercept.h"
#import "AWSIdentityProfileManager.h"

typedef void (^AWSSignInManagerCompletionBlock)(id result, AWSIdentityManagerAuthState authState, NSError *error);

@interface AWSSignInManager()

@property (atomic, copy) AWSSignInManagerCompletionBlock completionHandler;

@property (nonatomic, strong) id<AWSSignInProvider> currentSignInProvider;
@property (nonatomic, strong) id<AWSSignInProvider> potentialSignInProvider;

-(id<AWSSignInProvider>)signInProviderForKey:(NSString *)key;

@end

@implementation AWSSignInManager

static NSMutableDictionary<NSString *, id<AWSSignInProvider>> *signInProviderInfo = nil;
static AWSIdentityManager *identityManager;

+(instancetype)sharedInstance {
    static AWSSignInManager *_sharedSignInManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedSignInManager = [[AWSSignInManager alloc] init];
        signInProviderInfo = [[NSMutableDictionary alloc] init];
        identityManager = [AWSIdentityManager defaultIdentityManager];
    });
    
    return _sharedSignInManager;
}

-(AWSIdentityManagerAuthState)authState {
    if (identityManager.identityId && self.currentSignInProvider) {
        return AWSIdentityManagerAuthStateAuthenticated;
    } else if (identityManager.identityId) {
        return AWSIdentityManagerAuthStateUnauthenticated;
    }
    return AWSIdentityManagerAuthStateNoCredentials;
}

-(void)registerAWSSignInProvider:(id<AWSSignInProvider>)signInProvider {
    [signInProviderInfo setValue:signInProvider
                          forKey:signInProvider.identityProviderName];
    
}

-(id<AWSSignInProvider>)signInProviderForKey:(NSString *)key {
    return [signInProviderInfo objectForKey:key];
}

-(NSArray<NSString *>*)getRegisterdSignInProviders {
    return [signInProviderInfo allKeys];
}

- (BOOL)isLoggedIn {
    return self.currentSignInProvider.isLoggedIn || self.potentialSignInProvider.isLoggedIn;
}


- (void)wipeAll {
    [identityManager.credentialsProvider clearKeychain];
}

- (void)logoutWithCompletionHandler:(void (^)(id result, AWSIdentityManagerAuthState authState, NSError *error))completionHandler {
    if ([self.currentSignInProvider isLoggedIn]) {
        [self.currentSignInProvider logout];
        [[AWSIdentityProfileManager sharedInstance] clearProfileForProviderKey:self.currentSignInProvider.identityProviderName];
    }
    
    [self wipeAll];
    
    self.currentSignInProvider = nil;
    
    [[identityManager.credentialsProvider getIdentityId] continueWithBlock:^id _Nullable(AWSTask<NSString *> * _Nonnull task) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (task.result) {
                completionHandler(task.result, AWSIdentityManagerAuthStateUnauthenticated, task.error);
            } else {
                completionHandler(task.result, AWSIdentityManagerAuthStateNoCredentials, task.error);
            }
        });
        return nil;
    }];
}

- (void)loginWithSignInProviderKey:(NSString *)signInProviderKey
              completionHandler:(void (^)(id result, AWSIdentityManagerAuthState authState, NSError *error))completionHandler {
    
    if ([self signInProviderForKey:signInProviderKey]) {
        self.potentialSignInProvider = [self signInProviderForKey:signInProviderKey];
    } else {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:@"The sign in provider is not registered as an available sign in provider. Please register using `registerAWSSignInProvider:`."
                                     userInfo:nil];
    }
    
    self.completionHandler = completionHandler;
    [self.potentialSignInProvider login:completionHandler];
}

- (void)resumeSessionWithCompletionHandler:(void (^)(id result, AWSIdentityManagerAuthState authState, NSError *error))completionHandler {

    self.completionHandler = completionHandler;
    
    for(NSString *key in [self getRegisterdSignInProviders]) {
        if ([[self signInProviderForKey:key] isLoggedIn]) {
            self.potentialSignInProvider = [self signInProviderForKey:key];
        }
    }
    
    [self.potentialSignInProvider reloadSession];
    
    if (self.potentialSignInProvider == nil) {
        [self completeLogin];
    }
}

- (void)completeLogin {
    // Force a refresh of credentials to see if we need to merge
    [identityManager.credentialsProvider invalidateCachedTemporaryCredentials];
    
    if (self.potentialSignInProvider) {
        self.currentSignInProvider = self.potentialSignInProvider;
        self.potentialSignInProvider = nil;
        [[AWSIdentityProfileManager sharedInstance] loadProfileForProviderKey:self.currentSignInProvider.identityProviderName];
    }
    
    [[identityManager.credentialsProvider credentials] continueWithBlock:^id _Nullable(AWSTask<AWSCredentials *> * _Nonnull task) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // Determine Auth State
            AWSIdentityManagerAuthState authState = [AWSSignInManager sharedInstance].authState;
            self.completionHandler(task.result, authState, task.error);
        });
        return nil;
    }];
}

- (BOOL)interceptApplication:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    for(NSString *key in [self getRegisterdSignInProviders]) {
        id<AWSSignInProvider> signInProvider = [self signInProviderForKey:key];
        if ([signInProvider conformsToProtocol:@protocol(AWSSignInProviderApplicationIntercept)]) {
            [(id<AWSSignInProviderApplicationIntercept>)signInProvider interceptApplication:application
                                                              didFinishLaunchingWithOptions:launchOptions];
        }
    }
    
    return YES;
}

- (BOOL)interceptApplication:(UIApplication *)application
                     openURL:(NSURL *)url
           sourceApplication:(NSString *)sourceApplication
                  annotation:(id)annotation {
    if (self.potentialSignInProvider) {
        if ([self.potentialSignInProvider conformsToProtocol:@protocol(AWSSignInProviderApplicationIntercept)]) {
            id<AWSSignInProviderApplicationIntercept> provider = (id<AWSSignInProviderApplicationIntercept>)self.potentialSignInProvider;
            return [provider interceptApplication:application
                                          openURL:url
                                sourceApplication:sourceApplication
                                       annotation:annotation];
        }
    }

    return YES;
}

@end
