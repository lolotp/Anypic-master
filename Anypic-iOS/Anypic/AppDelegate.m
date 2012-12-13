//
//  AppDelegate.m
//  Anypic
//
//  Created by Héctor Ramos on 5/04/12.
//  Copyright (c) 2012 Parse. All rights reserved.
//

static NSString * const defaultsFilterDistanceKey = @"filterDistance";
static NSString * const defaultsLocationKey = @"currentLocation";

#import "AppDelegate.h"

#import "Reachability.h"
#import "MBProgressHUD.h"
#import "PAPHomeViewController.h"
#import "PAPLogInViewController.h"
#import "UIImage+ResizeAdditions.h"
#import "PAPAccountViewController.h"
#import "PAPWelcomeViewController.h"
#import "PAPActivityFeedViewController.h"
#import "PAPPhotoDetailsViewController.h"

#import "PAWWelcomeViewController.h"
#import "PAWWallViewController.h"

@interface AppDelegate () {
    NSMutableData *_data;
    BOOL firstLaunch;
}

//@property (nonatomic, strong) PAPHomeViewController *homeViewController;
@property (nonatomic, strong) PAWWallViewController *homeViewController;
@property (nonatomic, strong) PAPActivityFeedViewController *activityViewController;
//@property (nonatomic, strong) PAPWelcomeViewController *welcomeViewController;
@property (nonatomic, strong) PAWWelcomeViewController *welcomeViewController;

@property (nonatomic, strong) MBProgressHUD *hud;
@property (nonatomic, strong) NSTimer *autoFollowTimer;

@property (nonatomic, strong) Reachability *hostReach;
@property (nonatomic, strong) Reachability *internetReach;
@property (nonatomic, strong) Reachability *wifiReach;

- (void)setupAppearance;
- (BOOL)shouldProceedToMainInterface:(PFUser *)user;
- (BOOL)handleActionURL:(NSURL *)url;
@end

@implementation AppDelegate

@synthesize window;
@synthesize navController;
@synthesize tabBarController;
@synthesize networkStatus;

@synthesize homeViewController;
@synthesize activityViewController;
@synthesize welcomeViewController;

@synthesize hud;
@synthesize autoFollowTimer;

@synthesize hostReach;
@synthesize internetReach;
@synthesize wifiReach;

@synthesize filterDistance;
@synthesize currentLocation;

- (void)setFilterDistance:(CLLocationAccuracy)aFilterDistance
{
	filterDistance = aFilterDistance;
    
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setDouble:filterDistance forKey:defaultsFilterDistanceKey];
	[userDefaults synchronize];
    
	// Notify the app of the filterDistance change:
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithDouble:filterDistance] forKey:kPAWFilterDistanceKey];
	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:kPAWFilterDistanceChangeNotification object:nil userInfo:userInfo];
	});
}

- (void)setCurrentLocation:(CLLocation *)aCurrentLocation
{
	currentLocation = aCurrentLocation;
    
	// Notify the app of the location change:
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:currentLocation forKey:kPAWLocationKey];
	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:kPAWLocationChangeNotification object:nil userInfo:userInfo];
	});
}

#pragma mark UIApplicationDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    // ****************************************************************************
    // Parse initialization
    // [Parse setApplicationId:@"APPLICATION_ID" clientKey:@"CLIENT_KEY"];
    //
    // Make sure to update your URL scheme to match this facebook id. It should be "fbFACEBOOK_APP_ID" where FACEBOOK_APP_ID is your Facebook app's id.
    // You may set one up at https://developers.facebook.com/apps
    // [PFFacebookUtils initializeWithApplicationId:@"FACEBOOK_APP_ID"];
    // ****************************************************************************
    
    [Parse setApplicationId:kPAWParseApplicationID clientKey:kPAWParseClientKey];
	
	// Grab values from NSUserDefaults:
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
	// Desired search radius:
	if ([userDefaults doubleForKey:defaultsFilterDistanceKey]) {
		// use the ivar instead of self.accuracy to avoid an unnecessary write to NAND on launch.
		filterDistance = [userDefaults doubleForKey:defaultsFilterDistanceKey];
	} else {
		// if we have no accuracy in defaults, set it to 1000 feet.
		self.filterDistance = 1000 * kPAWFeetToMeters;
	}

    if (application.applicationIconBadgeNumber != 0) {
        application.applicationIconBadgeNumber = 0;
        [[PFInstallation currentInstallation] saveEventually];
    }

    PFACL *defaultACL = [PFACL ACL];
    // Enable public read access by default, with any newly created PFObjects belonging to the current user
    [defaultACL setPublicReadAccess:YES];
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];

    // Set up our app's global UIAppearance
    [self setupAppearance];

    // Use Reachability to monitor connectivity
    [self monitorReachability];

    self.welcomeViewController = [[PAWWelcomeViewController alloc] init];

    self.navController = [[UINavigationController alloc] initWithRootViewController:self.welcomeViewController];
    self.navController.navigationBarHidden = YES;

    self.window.rootViewController = self.navController;
    [self.window makeKeyAndVisible];

    [self handlePush:launchOptions];

    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    BOOL handledActionURL = [self handleActionURL:url];
    
    if (handledActionURL) {
        return YES;
    }
    
    return [PFFacebookUtils handleOpenURL:url];
} 

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
    [PFPush storeDeviceToken:newDeviceToken];

    if (application.applicationIconBadgeNumber != 0) {
        application.applicationIconBadgeNumber = 0;
    }

    [[PFInstallation currentInstallation] addUniqueObject:@"" forKey:kPAPInstallationChannelsKey];
    if ([PFUser currentUser]) {
        // Make sure they are subscribed to their private push channel
        NSString *privateChannelName = [[PFUser currentUser] objectForKey:kPAPUserPrivateChannelKey];
        if (privateChannelName && privateChannelName.length > 0) {
            NSLog(@"Subscribing user to %@", privateChannelName);
            [[PFInstallation currentInstallation] addUniqueObject:privateChannelName forKey:kPAPInstallationChannelsKey];
        }
    }
    [[PFInstallation currentInstallation] saveEventually];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	if ([error code] != 3010) { // 3010 is for the iPhone Simulator
        NSLog(@"Application failed to register for push notifications: %@", error);
	}
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [[NSNotificationCenter defaultCenter] postNotificationName:PAPAppDelegateApplicationDidReceiveRemoteNotification object:nil userInfo:userInfo];
    
    if ([PFUser currentUser]) {
        if ([self.tabBarController viewControllers].count > PAPActivityTabBarItemIndex) {
            UITabBarItem *tabBarItem = [[[self.tabBarController viewControllers] objectAtIndex:PAPActivityTabBarItemIndex] tabBarItem];
            
            NSString *currentBadgeValue = tabBarItem.badgeValue;
            
            if (currentBadgeValue && currentBadgeValue.length > 0) {
                NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
                NSNumber *badgeValue = [numberFormatter numberFromString:currentBadgeValue];
                NSNumber *newBadgeValue = [NSNumber numberWithInt:[badgeValue intValue] + 1];
                tabBarItem.badgeValue = [numberFormatter stringFromNumber:newBadgeValue];
            } else {
                tabBarItem.badgeValue = @"1";
            }
        }
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    if (application.applicationIconBadgeNumber != 0) {
        application.applicationIconBadgeNumber = 0;
        [[PFInstallation currentInstallation] saveEventually];
    }
}


#pragma mark - UITabBarControllerDelegate

- (BOOL)tabBarController:(UITabBarController *)aTabBarController shouldSelectViewController:(UIViewController *)viewController {
    // The empty UITabBarItem behind our Camera button should not load a view controller
    return ![viewController isEqual:[[aTabBarController viewControllers] objectAtIndex:PAPEmptyTabBarItemIndex]];
}


#pragma mark - PFLoginViewController

- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user {
    // user has logged in - we need to fetch all of their Facebook data before we let them in
    if (![self shouldProceedToMainInterface:user]) {
        self.hud = [MBProgressHUD showHUDAddedTo:self.navController.presentedViewController.view animated:YES];
        [self.hud setLabelText:@"Loading"];
        [self.hud setDimBackground:YES];
    }
    
    PF_FBRequest *request = [PF_FBRequest requestForGraphPath:@"me/?fields=name,picture"];
    [request setDelegate:self];
    [request startWithCompletionHandler:NULL];

    // Subscribe to private push channel
    if (user) {
        NSString *privateChannelName = [NSString stringWithFormat:@"user_%@", [user objectId]];
        [[PFInstallation currentInstallation] setObject:[PFUser currentUser] forKey:kPAPInstallationUserKey];
        [[PFInstallation currentInstallation] addUniqueObject:privateChannelName forKey:kPAPInstallationChannelsKey];
        [[PFInstallation currentInstallation] saveEventually];
        [user setObject:privateChannelName forKey:kPAPUserPrivateChannelKey];
    }
}

#pragma mark - PF_FBRequestDelegate
- (void)request:(PF_FBRequest *)request didLoad:(id)result {
    // This method is called twice - once for the user's /me profile, and a second time when obtaining their friends. We will try and handle both scenarios in a single method.
    
    NSArray *data = [result objectForKey:@"data"];
    
    if (data) {
        // we have friends data
        NSMutableArray *facebookIds = [[NSMutableArray alloc] initWithCapacity:data.count];
        for (NSDictionary *friendData in data) {
            [facebookIds addObject:[friendData objectForKey:@"id"]];
        }
        
        // cache friend data
        [[PAPCache sharedCache] setFacebookFriends:facebookIds];
        
        if (![[PFUser currentUser] objectForKey:kPAPUserAlreadyAutoFollowedFacebookFriendsKey]) {
            [self.hud setLabelText:@"Following Friends"];
            firstLaunch = YES;
            
            [[PFUser currentUser] setObject:[NSNumber numberWithBool:YES] forKey:kPAPUserAlreadyAutoFollowedFacebookFriendsKey];
            NSError *error = nil;
            
            // find common Facebook friends already using Anypic
            PFQuery *facebookFriendsQuery = [PFUser query];
            [facebookFriendsQuery whereKey:kPAPUserFacebookIDKey containedIn:facebookIds];
            
            // auto-follow Parse employees
            PFQuery *parseEmployeesQuery = [PFUser query];
            [parseEmployeesQuery whereKey:kPAPUserFacebookIDKey containedIn:kPAPParseEmployeeAccounts];
            
            // combined query
            PFQuery *query = [PFQuery orQueryWithSubqueries:[NSArray arrayWithObjects:parseEmployeesQuery,facebookFriendsQuery, nil]];
            
            NSArray *anypicFriends = [query findObjects:&error];

            if (!error) {
                [anypicFriends enumerateObjectsUsingBlock:^(PFUser *newFriend, NSUInteger idx, BOOL *stop) {
                    PFObject *joinActivity = [PFObject objectWithClassName:kPAPActivityClassKey];
                    [joinActivity setObject:[PFUser currentUser] forKey:kPAPActivityFromUserKey];
                    [joinActivity setObject:newFriend forKey:kPAPActivityToUserKey];
                    [joinActivity setObject:kPAPActivityTypeJoined forKey:kPAPActivityTypeKey];

                    PFACL *joinACL = [PFACL ACL];
                    [joinACL setPublicReadAccess:YES];
                    joinActivity.ACL = joinACL;

                    // make sure our join activity is always earlier than a follow
                    [joinActivity saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        [PAPUtility followUserInBackground:newFriend block:^(BOOL succeeded, NSError *error) {
                            // This block will be executed once for each friend that is followed.
                            // We need to refresh the timeline when we are following at least a few friends
                            // Use a timer to avoid refreshing innecessarily
                            if (self.autoFollowTimer) {
                                [self.autoFollowTimer invalidate];
                            }

                            self.autoFollowTimer = [NSTimer scheduledTimerWithTimeInterval:3.0f target:self selector:@selector(autoFollowTimerFired:) userInfo:nil repeats:NO];
                        }];
                    }];
                }];
            }
            
            if (![self shouldProceedToMainInterface:[PFUser currentUser]]) {
                [self logOut];
                return;
            }
            
            if (!error) {
                [MBProgressHUD hideHUDForView:self.navController.presentedViewController.view animated:NO];
                if (anypicFriends.count > 0) {
                    self.hud = [MBProgressHUD showHUDAddedTo:self.homeViewController.view animated:NO];
                    [self.hud setDimBackground:YES];
                    [self.hud setLabelText:@"Following Friends"];
                } else {
                    [self.homeViewController.wallPostsTableViewController loadObjects];
                }
            }
        }
        
        [[PFUser currentUser] saveEventually];
    } else {
        [self.hud setLabelText:@"Creating Profile"];
        NSString *facebookId = [result objectForKey:@"id"];
        NSString *facebookName = [result objectForKey:@"name"];
        
        if (facebookName && facebookName != 0) {
            [[PFUser currentUser] setObject:facebookName forKey:kPAPUserDisplayNameKey];
        }

        if (facebookId && facebookId != 0) {
            [[PFUser currentUser] setObject:facebookId forKey:kPAPUserFacebookIDKey];
        }
        
        PF_FBRequest *request = [PF_FBRequest requestForMyFriends];
        [request setDelegate:self];
        [request startWithCompletionHandler:nil];
    }
}

- (void)request:(PF_FBRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"Facebook error: %@", error);
    
    if ([PFUser currentUser]) {
        if ([[[[error userInfo] objectForKey:@"error"] objectForKey:@"type"] 
             isEqualToString: @"OAuthException"]) {
            NSLog(@"The facebook token was invalidated");
            [self logOut];
        }
    }
}


#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    _data = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [PAPUtility processFacebookProfilePictureData:_data];
}

#pragma mark - AppDelegate

- (BOOL)isParseReachable {
    return self.networkStatus != NotReachable;
}

- (void)presentLoginViewControllerAnimated:(BOOL)animated {
    PAPLogInViewController *loginViewController = [[PAPLogInViewController alloc] init];
    [loginViewController setDelegate:self];
    loginViewController.fields = PFLogInFieldsFacebook;
    loginViewController.facebookPermissions = [NSArray arrayWithObjects:@"user_about_me", nil];
    
    [self.welcomeViewController presentModalViewController:loginViewController animated:NO];
}


- (void)presentLoginViewController {
    [self presentLoginViewControllerAnimated:YES];
}

- (void)presentTabBarController {    
    self.tabBarController = [[PAPTabBarController alloc] init];
    //self.homeViewController = [[PAPHomeViewController alloc] initWithStyle:UITableViewStylePlain];
	self.homeViewController = [[PAWWallViewController alloc] initWithNibName:nil bundle:nil];
    [self.homeViewController.wallPostsTableViewController setFirstLaunch:firstLaunch];
    self.activityViewController = [[PAPActivityFeedViewController alloc] initWithStyle:UITableViewStylePlain];
    
    UINavigationController *homeNavigationController = [[UINavigationController alloc] initWithRootViewController:self.homeViewController];
    UINavigationController *emptyNavigationController = [[UINavigationController alloc] init];
    UINavigationController *activityFeedNavigationController = [[UINavigationController alloc] initWithRootViewController:self.activityViewController];
    
    [PAPUtility addBottomDropShadowToNavigationBarForNavigationController:homeNavigationController];
    [PAPUtility addBottomDropShadowToNavigationBarForNavigationController:emptyNavigationController];
    [PAPUtility addBottomDropShadowToNavigationBarForNavigationController:activityFeedNavigationController];
    
    UITabBarItem *homeTabBarItem = [[UITabBarItem alloc] initWithTitle:@"Home" image:nil tag:0];
    [homeTabBarItem setFinishedSelectedImage:[UIImage imageNamed:@"IconHomeSelected.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"IconHome.png"]];
    [homeTabBarItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                            [UIColor colorWithRed:86.0f/255.0f green:55.0f/255.0f blue:42.0f/255.0f alpha:1.0f], UITextAttributeTextColor,
                                            nil] forState:UIControlStateNormal];
    [homeTabBarItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                            [UIColor colorWithRed:129.0f/255.0f green:99.0f/255.0f blue:69.0f/255.0f alpha:1.0f], UITextAttributeTextColor,
                                            nil] forState:UIControlStateSelected];
    
    UITabBarItem *activityFeedTabBarItem = [[UITabBarItem alloc] initWithTitle:@"Activity" image:nil tag:0];
    [activityFeedTabBarItem setFinishedSelectedImage:[UIImage imageNamed:@"IconTimelineSelected.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"IconTimeline.png"]];
    [activityFeedTabBarItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    [UIColor colorWithRed:86.0f/255.0f green:55.0f/255.0f blue:42.0f/255.0f alpha:1.0f], UITextAttributeTextColor,
                                                    nil] forState:UIControlStateNormal];
    [activityFeedTabBarItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    [UIColor colorWithRed:129.0f/255.0f green:99.0f/255.0f blue:69.0f/255.0f alpha:1.0f], UITextAttributeTextColor,
                                                    nil] forState:UIControlStateSelected];
    
    [homeNavigationController setTabBarItem:homeTabBarItem];
    [activityFeedNavigationController setTabBarItem:activityFeedTabBarItem];
    
    [self.tabBarController setDelegate:self];
    [self.tabBarController setViewControllers:[NSArray arrayWithObjects:homeNavigationController, emptyNavigationController, activityFeedNavigationController, nil]];
    
    [self.navController setViewControllers:[NSArray arrayWithObjects:self.welcomeViewController, self.tabBarController, nil] animated:NO];
    
    
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge|
     UIRemoteNotificationTypeAlert|
     UIRemoteNotificationTypeSound];
    
    
    NSLog(@"Downloading user's profile picture");
    // Download user's profile picture
    NSURL *profilePictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", [[PFUser currentUser] objectForKey:kPAPUserFacebookIDKey]]];
    NSURLRequest *profilePictureURLRequest = [NSURLRequest requestWithURL:profilePictureURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0f]; // Facebook profile picture cache policy: Expires in 2 weeks
    [NSURLConnection connectionWithRequest:profilePictureURLRequest delegate:self];
}

- (void)logOut {
    // clear cache
    [[PAPCache sharedCache] clear];

    // clear NSUserDefaults
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPAPUserDefaultsCacheFacebookFriendsKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPAPUserDefaultsActivityFeedViewControllerLastRefreshKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    // Unsubscribe from push notifications by clearing the channels key (leaving only broadcast enabled).
    [[PFInstallation currentInstallation] setObject:[NSArray arrayWithObject:@""] forKey:kPAPInstallationChannelsKey];
    [[PFInstallation currentInstallation] removeObjectForKey:kPAPInstallationUserKey];
    [[PFInstallation currentInstallation] saveInBackground];
    
    // Log out
    [PFUser logOut];
    
    // clear out cached data, view controllers, etc
    [self.navController popToRootViewControllerAnimated:NO];
    
    //[self presentLoginViewController];
    
    self.homeViewController = nil;
    self.activityViewController = nil;
}


#pragma mark - ()

- (void)setupAppearance {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
    
    [[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:0.498f green:0.388f blue:0.329f alpha:1.0f]];
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                          [UIColor whiteColor],UITextAttributeTextColor, 
                                                          [UIColor colorWithWhite:0.0f alpha:0.750f],UITextAttributeTextShadowColor, 
                                                          [NSValue valueWithCGSize:CGSizeMake(0.0f, 1.0f)],UITextAttributeTextShadowOffset, 
                                                          nil]];
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"BackgroundNavigationBar.png"] forBarMetrics:UIBarMetricsDefault];
    
    [[UIButton appearanceWhenContainedIn:[UINavigationBar class], nil] setBackgroundImage:[UIImage imageNamed:@"ButtonNavigationBar.png"] forState:UIControlStateNormal];
    [[UIButton appearanceWhenContainedIn:[UINavigationBar class], nil] setBackgroundImage:[UIImage imageNamed:@"ButtonNavigationBarSelected.png"] forState:UIControlStateHighlighted];
    [[UIButton appearanceWhenContainedIn:[UINavigationBar class], nil] setTitleColor:[UIColor colorWithRed:214.0f/255.0f green:210.0f/255.0f blue:197.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
    
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:[UIImage imageNamed:@"ButtonBack.png"]
                                                      forState:UIControlStateNormal
                                                    barMetrics:UIBarMetricsDefault];
    
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:[UIImage imageNamed:@"ButtonBackSelected.png"]
                                                      forState:UIControlStateSelected
                                                    barMetrics:UIBarMetricsDefault];

    [[UIBarButtonItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                          [UIColor colorWithRed:214.0f/255.0f green:210.0f/255.0f blue:197.0f/255.0f alpha:1.0f],UITextAttributeTextColor, 
                                                          [UIColor colorWithWhite:0.0f alpha:0.750f],UITextAttributeTextShadowColor, 
                                                          [NSValue valueWithCGSize:CGSizeMake(0.0f, 1.0f)],UITextAttributeTextShadowOffset, 
                                                          nil] forState:UIControlStateNormal];
    
    [[UISearchBar appearance] setTintColor:[UIColor colorWithRed:32.0f/255.0f green:19.0f/255.0f blue:16.0f/255.0f alpha:1.0f]];
}

- (void)monitorReachability {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:ReachabilityChangedNotification object:nil];
    
    self.hostReach = [Reachability reachabilityWithHostName: @"api.parse.com"];
    [self.hostReach startNotifier];
    
    self.internetReach = [Reachability reachabilityForInternetConnection];
    [self.internetReach startNotifier];
    
    self.wifiReach = [Reachability reachabilityForLocalWiFi];
    [self.wifiReach startNotifier];
}

- (void)handlePush:(NSDictionary *)launchOptions {

    // If the app was launched in response to a push notification, we'll handle the payload here
    NSDictionary *remoteNotificationPayload = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteNotificationPayload) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PAPAppDelegateApplicationDidReceiveRemoteNotification object:nil userInfo:remoteNotificationPayload];
        
        if ([PFUser currentUser]) {
            // if the push notification payload references a photo, we will attempt to push this view controller into view
            NSString *photoObjectId = [remoteNotificationPayload objectForKey:kPAPPushPayloadPhotoObjectIdKey];
            NSString *fromObjectId = [remoteNotificationPayload objectForKey:kPAPPushPayloadFromUserObjectIdKey];
            if (photoObjectId && photoObjectId.length > 0) {
                // check if this photo is already available locally.

                PFObject *targetPhoto = [PFObject objectWithoutDataWithClassName:kPAPPhotoClassKey objectId:photoObjectId];
                for (PFObject *photo in self.homeViewController.wallPostsTableViewController.objects) {
                    if ([photo.objectId isEqualToString:photoObjectId]) {
                        NSLog(@"Found a local copy");
                        targetPhoto = photo;
                        break;
                    }
                }

                // if we have a local copy of this photo, this won't result in a network fetch
                [targetPhoto fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                    if (!error) {
                        UINavigationController *homeNavigationController = [[self.tabBarController viewControllers] objectAtIndex:PAPHomeTabBarItemIndex];
                        [self.tabBarController setSelectedViewController:homeNavigationController];

                        PAPPhotoDetailsViewController *detailViewController = [[PAPPhotoDetailsViewController alloc] initWithPhoto:object];
                        [homeNavigationController pushViewController:detailViewController animated:YES];
                    }
                }];
            } else if (fromObjectId && fromObjectId.length > 0) {
                // load fromUser's profile
                    
                PFQuery *query = [PFUser query];
                query.cachePolicy = kPFCachePolicyCacheElseNetwork;
                [query getObjectInBackgroundWithId:fromObjectId block:^(PFObject *user, NSError *error) {
                    if (!error) {
                        UINavigationController *homeNavigationController = [[self.tabBarController viewControllers] objectAtIndex:PAPHomeTabBarItemIndex];
                        [self.tabBarController setSelectedViewController:homeNavigationController];

                        PAPAccountViewController *accountViewController = [[PAPAccountViewController alloc] initWithStyle:UITableViewStylePlain];
                        [accountViewController setUser:(PFUser *)user];
                        [homeNavigationController pushViewController:accountViewController animated:YES];
                    }
                }];

            }
        }
    }
}

- (void)autoFollowTimerFired:(NSTimer *)aTimer {
    [MBProgressHUD hideHUDForView:self.navController.presentedViewController.view animated:YES];
    [MBProgressHUD hideHUDForView:self.homeViewController.view animated:YES];
    [self.homeViewController.wallPostsTableViewController loadObjects];
}

- (BOOL)shouldProceedToMainInterface:(PFUser *)user {
    if ([PAPUtility userHasValidFacebookData:[PFUser currentUser]]) {
        NSLog(@"User has valid Facebook data, granting permission to use app.");
        [MBProgressHUD hideHUDForView:self.navController.presentedViewController.view animated:YES];
        [self presentTabBarController];

        [self.navController dismissModalViewControllerAnimated:YES];
        return YES;
    }
    
    return NO;
}

- (BOOL)handleActionURL:(NSURL *)url {
    if ([[url host] isEqualToString:kPAPLaunchURLHostTakePicture]) {
        if ([PFUser currentUser]) {
            return [self.tabBarController shouldPresentPhotoCaptureController];
        }
    }

    return NO;
}

//Called by Reachability whenever status changes.
- (void)reachabilityChanged:(NSNotification* )note {
    Reachability *curReach = (Reachability *)[note object];
    NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
    NSLog(@"Reachability changed: %@", curReach);
    networkStatus = [curReach currentReachabilityStatus];
    
    if ([self isParseReachable] && [PFUser currentUser] && self.homeViewController.wallPostsTableViewController.objects.count == 0) {
        // Refresh home timeline on network restoration. Takes care of a freshly installed app that failed to load the main timeline under bad network conditions.
        // In this case, they'd see the empty timeline placeholder and have no way of refreshing the timeline unless they followed someone.
        [self.homeViewController.wallPostsTableViewController loadObjects];
    }
}

@end
