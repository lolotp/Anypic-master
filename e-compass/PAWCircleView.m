#import "PAWCircleView.h"

@implementation PAWCircleView

@synthesize searchRadius;

- (id)initWithOverlay:(id <MKOverlay>)overlay {
	NSAssert(0, @"-initWithSearchRadius: is the designated initializer");
	return nil;
}

- (id)initWithSearchRadius:(PAWSearchRadius *)aSearchRadius;
{
	if ((self = [super initWithOverlay:aSearchRadius])) {
		[self.searchRadius addObserver:self forKeyPath:@"coordinate" options:0 context:nil];
		[self.searchRadius addObserver:self forKeyPath:@"radius" options:0 context:nil];
	}
    return self;
}

- (void)dealloc {
	[self.searchRadius removeObserver:self forKeyPath:@"coordinate"];
	[self.searchRadius removeObserver:self forKeyPath:@"radius"];
}

- (PAWSearchRadius *)searchRadius {
    return (PAWSearchRadius *)self.overlay;
}

- (void)createPath {
	CGMutablePathRef path = CGPathCreateMutable();
	CLLocationCoordinate2D center = self.searchRadius.coordinate;
	CGPoint centerPoint = [self pointForMapPoint:MKMapPointForCoordinate(center)];
	CGFloat radius = MKMapPointsPerMeterAtLatitude(center.latitude) * self.searchRadius.radius;
	CGPathAddArc(path, NULL, centerPoint.x, centerPoint.y, radius, 2 * M_PI, 0, true);
	
	self.path = path;
	CGPathRelease(path);
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
	[self invalidatePath];
}

@end
