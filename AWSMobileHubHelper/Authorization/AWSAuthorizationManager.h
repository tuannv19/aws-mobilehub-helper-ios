//
//  AWSAuthorizationManager.h
//
// Copyright 2016 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to
// copy, distribute and modify it.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern NSString * _Nonnull const AWSAuthorizationManagerErrorDomain;

typedef NS_ENUM(NSUInteger, AWSAuthorizationManagerError) {
    AWSAuthorizationErrorUserCancelledFlow,
    AWSAuthorizationErrorFailedToRetrieveAccessToken,
    AWSAuthorizationErrorMissingRequiredParameter,
};

@interface AWSAuthorizationManager : NSObject

/**
 * Singleton used to authorize user during OAuth1.0, 2.0, other flows.
 * @return the singleton
 */
+ (instancetype _Nonnull)sharedInstance;

/**
 * Utility method that constructs form encoded portion of url
 * i.e. @{@"grant": @"code", @"client_id": @"abc123"} -> @"grant=code&client_id=abc123&"
 *
 * @return the string representation of a form
 */
+ (NSString * _Nonnull)constructURIWithParameters:(NSDictionary * _Nonnull)params;

/**
 * Utility method that constructs dictionary from simple form encoded url
 * i.e. @"grant=code&client_id=abc123" -> @{@"grant": @"code", @"client_id": @"abc123"}
 *
 * @return the dictionary representation of a url encoded form
 */
+ (NSDictionary * _Nonnull)constructParametersWithURI:(NSString * _Nonnull)formString;

/**
 * Starts the authorization flow. Should be called from main thread.
 *
 * @param authorizeViewController The view controller that user sees right before they should see a login screen.
 * @param completionHandler The code that will follow after receiving successful login. Executes BEFORE login screen is dismissed.
 */
- (void)authorizeWithView:(UIViewController * _Nonnull)authorizeViewController completionHandler:(void (^ _Nullable)(id _Nullable result, NSError * _Nullable error)) completionHandler;

/**
 * Starts the refresh flow or possibly run the same authorize flow again.
 * Does not check if current accessToken is expired or not.
 *
 * @param refreshCompletionHandler The code that will follow after refreshing accessToken.
 */
- (void)refresh:(void (^ _Nullable)(id _Nullable result, NSError * _Nullable error))refreshCompletionHandler;

/**
 * This method should be placed in the AppDelegate to listen for the redirect URI.
 *
 * - (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
 *
 * @param url The url that the authorization flow gives back.
 * @return YES if the url matches an expected response, NO if it is not expected.
 */
- (BOOL)handleURL:(NSURL * _Nullable)url;

/**
 * @return the accessToken used for API calls
 */
- (NSString * _Nullable)getAccessToken;

/**
 * Starts the logout flow. Should be called from main thread.
 *
 * @param logoutViewController The view controller that user sees right before they should see a logout indication.
 * @param completionHandler The code that will follow after receiving successful login. Executes BEFORE login screen is dismissed.
 */
- (void)logout:(UIViewController * _Nonnull)logoutViewController completionHandler:(void (^ _Nullable)(id _Nullable result, NSError * _Nullable error)) completionHandler;

@end
