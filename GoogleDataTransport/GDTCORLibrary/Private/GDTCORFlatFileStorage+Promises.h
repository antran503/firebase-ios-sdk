//
//  GDTCORFlatFileStorage+Promises.h
//  GoogleDataTransport
//
//  Created by Maksym Malyhin on 2020-09-17.
//

#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORFlatFileStorage.h"

@class FBLPromise<ValueType>;

NS_ASSUME_NONNULL_BEGIN

@interface GDTCORFlatFileStorage (Promises)

- (FBLPromise<NSSet<NSNumber *> *> *)batchIDsForTarget:(GDTCORTarget)target;

- (FBLPromise<NSNull *> *)removeBatchWithID:(NSNumber *)batchID deleteEvents:(BOOL)deleteEvents;

@end

NS_ASSUME_NONNULL_END
