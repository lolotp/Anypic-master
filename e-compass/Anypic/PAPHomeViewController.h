#import "PAPPhotoTimelineViewController.h"
#import <MapKit/MapKit.h>
#import <Parse/Parse.h>

@interface PAPHomeViewController : PAPPhotoTimelineViewController <MKMapViewDelegate, CLLocationManagerDelegate>

@property (nonatomic, assign, getter = isFirstLaunch) BOOL firstLaunch;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) IBOutlet MKMapView *mapView;

@end
