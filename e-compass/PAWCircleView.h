#import <MapKit/MapKit.h>
#import "PAWSearchRadius.h"

@interface PAWCircleView : MKOverlayPathView

- (id)initWithSearchRadius:(PAWSearchRadius *)searchRadius;

@property (nonatomic, readonly, strong) PAWSearchRadius *searchRadius;

@end
