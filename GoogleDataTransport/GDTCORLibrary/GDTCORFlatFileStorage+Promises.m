//
//  GDTCORFlatFileStorage+Promises.m
//  GoogleDataTransport
//
//  Created by Maksym Malyhin on 2020-09-17.
//

#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORFlatFileStorage+Promises.h"

#import <FBLPromises/FBLPromises.h>

@implementation GDTCORFlatFileStorage (Promises)

- (FBLPromise<NSSet<NSNumber *> *> *)batchIDsForTarget:(GDTCORTarget)target {
  return [FBLPromise onQueue:self.storageQueue
        wrapObjectCompletion:^(FBLPromiseObjectCompletion _Nonnull handler) {
          [self batchIDsForTarget:target onComplete:handler];
        }];
}

- (FBLPromise<NSNull *> *)removeBatchWithID:(NSNumber *)batchID deleteEvents:(BOOL)deleteEvents {
  return [FBLPromise onQueue:self.storageQueue
              wrapCompletion:^(FBLPromiseCompletion _Nonnull handler) {
                [self removeBatchWithID:batchID deleteEvents:deleteEvents onComplete:handler];
              }];
}

- (FBLPromise<NSNull *> *)removeBatchesWithIDs:(NSSet<NSNumber *> *)batchIDs
                                  deleteEvents:(BOOL)deleteEvents {
  NSMutableArray<FBLPromise *> *removeBatchPromises =
      [NSMutableArray arrayWithCapacity:batchIDs.count];
  for (NSNumber *batchID in batchIDs) {
    [removeBatchPromises addObject:[self removeBatchWithID:batchID deleteEvents:deleteEvents]];
  }

  return [FBLPromise onQueue:self.storageQueue all:[removeBatchPromises copy]].thenOn(
      self.storageQueue, ^id(id result) {
        return [FBLPromise resolvedWith:[NSNull null]];
      });
}

- (FBLPromise<NSNull *> *)removeAllBatchesForTarget:(GDTCORTarget)target
                                       deleteEvents:(BOOL)deleteEvents {
  return
      [self batchIDsForTarget:target].thenOn(self.storageQueue, ^id(NSSet<NSNumber *> *batchIDs) {
        return [self removeBatchesWithIDs:batchIDs deleteEvents:NO];
      });
}

@end
