//
//  AWSSAMLSignInProvider.h
//  AWSSamlSignIn
//
// Copyright 2016 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to
// copy, distribute and modify it.
//

#import "AWSSignInProvider.h"
#import "AWSSignInProviderApplicationIntercept.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Any class over-riding the `AWSSAMLSignInProvider` class for implemeting `SAML` as a sign-in provider,
 *  should also adopt the `AWSSAMLSignInProviderInstance` protocol.
 */
@protocol AWSSAMLSignInProviderInstance

/**
 *  The shared instance of the class implementing `SAML` as a sign-in provider.
 *
 *  @return the shared instance of the class implementing `SAML` as a sign-in provider.
 */
+ (id<AWSSignInProvider>)sharedInstance;

@end

@interface AWSSAMLSignInProvider : NSObject <AWSSignInProvider, AWSSignInProviderApplicationIntercept>

#pragma mark - Initializer

/*
 The only initializer for AWSSAMLSignInProvider. This initializer has to be used by the class over-riding AWSSAMLSignInProvider.
 @param uniqueIdentifier     The unique identifier string for the SAML Sign In Provider
 @param identityProviderName The identifier provider name for SAML provider (the Identity Provider ARN for SAML)
 @return instance of AWSSAMLSignInProvider
 */
- (instancetype)initWithIdentifier:(NSString *)uniqueIdentifier
              identityProviderName:(NSString *)identityProviderName;

#pragma mark - Mandatory Override Methods

// The user is expected to over the methods in this pragma mark

/**
 *  This method will be called when `loginWithSignInProvider` is invoked from `AWSIdentityManager`.
 *  Developer is expected to call `setResult` on `taskCompletionSource` with the SAML login token on a successful login,
 *  or `setError` when the login is cancelled or encounters an error.
 *
 *  The token internally is stored in the keychain store, and a flag is set in `NSUserDefaults` indicating the user is logged in using this `SAML` sign-in provider.
 *
 *  ** Objective-C ***
 *  - (void)handleLoginWithTaskCompletionSource:(AWSTaskCompletionSource<NSString *> *)taskCompletionSource {
 *       // handle login logic
 *       if(loginSuccessful) {
 *          [taskCompletionSource setResult:@"SuccessfullyGeneratedToken"];
 *       } else {
 *          [taskCompletionSource setError:error];
 *       }
 *    }
 *
 *  ** Swift **
 *  func handleLogicWithTaskCompletionSource(taskCompletionSource: AWSTaskCompletionSource<String>) {
 *      if(loginSuccessful) {
 *          taskCompletionSource.setResult("SuccessfullyGeneratedToken")
 *       } else {
 *          taskCompletionSource.setError(error)
 *       }
 *  }
 *
 *  @param taskCompletionSource the `AWSTaskCompletionSource` object which is used to call `setResult` or `setError`
 */
- (void)handleLoginWithTaskCompletionSource:(AWSTaskCompletionSource<NSString *> *)taskCompletionSource;

/**
 *  This method is called whenver the cognito credentials are refreshed or when app is loaded from background state / closed state.
 *  The previous saved token can be fetched using `fetchStoredToken`, and if it is valid the same can be returned without refreshing.
 *
 *  @return an instance of `AWSTask`. `task.result` should contain the valid token in case of successful token fetch, or `task.error` should be set
 */
- (AWSTask<NSString *>*)fetchLatestToken;

#pragma mark - Optional Override Methods

/**
 * Passes parameters used to launch the application to the current identity provider.
 * It can be used to complete the user sign-in call flow, which uses a browser to
 * get information from the user, directly. The current sign-in provider will be set to nil if
 * the sign-in provider is not registered using `registerAWSSignInProvider:forKey` method  of
 * `AWSSignInProviderFactory` class.
 *
 * @param application application
 * @param launchOptions options used to launch the application
 * @return true if this call handled the operation
 */
- (BOOL)interceptApplication:(UIApplication *)application
didFinishLaunchingWithOptions:(nullable NSDictionary *)launchOptions;

/**
 * Passes parameters used to launch the application to the current identity provider.
 * It can be used to complete the user sign-in call flow, which uses a browser to
 * get information from the user, directly. The developer should store a reference to
 * the `taskCompletionSource` instance provided by the `handleLoginWithTaskCompletionSouce`
 * method to set the result with successfully retrieved token.
 *
 * @param application application
 * @param url url used to open the application
 * @param sourceApplication source application
 * @param annotation annotation
 * @return true if this call handled the operation
 */
- (BOOL)interceptApplication:(UIApplication *)application
                     openURL:(NSURL *)url
           sourceApplication:(nullable NSString *)sourceApplication
                  annotation:(id)annotation;

#pragma mark - Instance Methods

/**
 *  Can be used to store a reference of teh view controller from which `loginWithSignInProvider` is invoked by `AWSIdentityManager`
 *
 *  @param signInViewController the signInViewController object whose reference needs to be stored
 */
- (void)setViewControllerForSignIn:(UIViewController *)signInViewController;

/**
 *  This method returns the view controller whose reference was stored using `setViewControllerForSignIn`
 *
 *  @return the stored view controller if set, else `nil`
 */
- (UIViewController *)getViewControllerForSignIn;

/**
 *  Returns the token stored in keychain as-is (without refreshing)
 *
 *  @return the token if available in keychain, else `nil`
 */
- (NSString *)fetchStoredToken;

/**
 *  Determines if the user is logged in based on the token available in keychain and if the login flag is set internally.
 *
 *  @return `YES` if the user is logged in using `SAML` sign-in provider instance
 */
- (BOOL)isLoggedIn;

@end

NS_ASSUME_NONNULL_END
