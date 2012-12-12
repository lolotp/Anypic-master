//
//  AppDelegate.h
//  Anypic
//
//  Created by Héctor Ramos on 5/04/12.
//  Copyright (c) 2012 Parse. All rights reserved.
//

static NSUInteger const kPAWWallPostMaximumCharacterCount = 140;

static double const kPAWFeetToMeters = 0.3048; // this is an exact value.
static double const kPAWFeetToMiles = 5280.0; // this is an exact value.
static double const kPAWWallPostMaximumSearchDistance = 100.0;
static double const kPAWMetersInAKilometer = 1000.0; // this is an exact value.

static NSUInteger const kPAWWallPostsSearch = 20; // query limit for pins and tableviewcells

// Parse API key constants:
static NSString * const kPAWParseApplicationID = @"0B2w4U4R5tq7ShH9Sg7nJMXbKA4lIfzodC1o4mEa";
static NSString * const kPAWParseClientKey = @"ol4rEuPgMKyL91RHMBfQPIqvxCGwAR2IOxXdKhpb";

static NSString * const kPAWParsePostsClassKey = @"Posts";
static NSString * const kPAWParseUserKey = @"user";
static NSString * const kPAWParseUsernameKey = @"username";
static NSString * const kPAWParseTextKey = @"text";
static NSString * const kPAWParseLocationKey = @"location";

// NSNotification userInfo keys:
static NSString * const kPAWFilterDistanceKey = @"filterDistance";
static NSString * const kPAWLocationKey = @"location";

// Notification names:
static NSString * const kPAWFilterDistanceChangeNotification = @"kPAWFilterDistanceChangeNotification";
static NSString * const kPAWLocationChangeNotification = @"kPAWLocationChangeNotification";
static NSString * const kPAWPostCreatedNotification = @"kPAWPostCreatedNotification";

// UI strings:
static NSString * const kPAWWallCantViewPost = @"Can’t view post! Get closer.";

#define PAWLocationAccuracy double

#import "PAPTabBarController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, PFLogInViewControllerDelegate, PF_FBRequestDelegate, NSURLConnectionDataDelegate, UITabBarControllerDelegate>

@property (nonatomic, strong) UIWindow *window;

@property (nonatomic, strong) PAPTabBarController *tabBarController;
@property (nonatomic, strong) UINavigationController *navController;

@property (nonatomic, readonly) int networkStatus;

@property (nonatomic, assign) CLLocationAccuracy filterDistance;
@property (nonatomic, strong) CLLocation *currentLocation;

- (BOOL)isParseReachable;

- (void)presentLoginViewController;
- (void)presentLoginViewControllerAnimated:(BOOL)animated;
- (void)presentTabBarController;

- (void)logOut;


@end
