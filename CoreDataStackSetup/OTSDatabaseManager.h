@import UIKit;

typedef void(^OTSDatabaseManagerCompletionHandler)(BOOL suceeded, NSError *error);

@interface OTSDatabaseManager : NSObject

@property (strong, nonatomic, readonly) NSManagedObjectContext *mainThreadManagedObjectContext;

- (instancetype)initWithModelName:(NSString *)modelName NS_DESIGNATED_INITIALIZER;

- (void)setupCoreDataStackWithCompletionHandler:(OTSDatabaseManagerCompletionHandler)handler;
- (void)saveDataWithCompletionHandler:(OTSDatabaseManagerCompletionHandler)handler;

@end
