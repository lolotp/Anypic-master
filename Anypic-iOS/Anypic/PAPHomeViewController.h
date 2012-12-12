//
//  PAPHomeViewController.h
//  Anypic
//
//  Created by Héctor Ramos on 5/3/12.
//  Copyright (c) 2012 Parse. All rights reserved.
//

#import "PAPPhotoTimelineViewController.h"
#import <MapKit/MapKit.h>
#import <Parse/Parse.h>

@interface PAPHomeViewController : PAPPhotoTimelineViewController <MKMapViewDelegate, CLLocationManagerDelegate>

@property (nonatomic, assign, getter = isFirstLaunch) BOOL firstLaunch;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) IBOutlet MKMapView *mapView;

@end
