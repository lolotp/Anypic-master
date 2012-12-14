#import "PAPActivityCell.h"

@interface PAPActivityFeedViewController : PFQueryTableViewController <PAPActivityCellDelegate>

+ (NSString *)stringForActivityType:(NSString *)activityType;

@end
