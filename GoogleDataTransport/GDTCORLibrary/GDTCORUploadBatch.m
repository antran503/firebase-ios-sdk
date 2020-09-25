//
//  GDTCORUploadBatch.m
//  GoogleDataTransport
//
//  Created by Maksym Malyhin on 2020-09-18.
//

#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORUploadBatch.h"

@implementation GDTCORUploadBatch

- (instancetype)initWithBatchID:(NSNumber *)batchID events:(NSSet<GDTCOREvent *> *)events {
  self = [super init];
  if (self) {
    _batchID = batchID;
    _events = events;
  }
  return self;
}


@end
