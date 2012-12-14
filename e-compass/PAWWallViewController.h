#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <Parse/Parse.h>
#import "PAWPost.h"
#import "PAPHomeViewController.h"

@interface PAWWallViewController : UIViewController <MKMapViewDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) PAPHomeViewController *wallPostsTableViewController;

@end

@protocol PAWWallViewControllerHighlight <NSObject>

//- (void)highlightCellForPost:(PAWPost *)post;
//- (void)unhighlightCellForPost:(PAWPost *)post;

@end
