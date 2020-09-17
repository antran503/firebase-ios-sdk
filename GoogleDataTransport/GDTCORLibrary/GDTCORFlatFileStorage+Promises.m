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

@end
