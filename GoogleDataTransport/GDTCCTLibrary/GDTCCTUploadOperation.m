//
//  GDTCCTUploadOperation.m
//  GoogleDataTransport
//
//  Created by Maksym Malyhin on 2020-09-21.
//

#import "GDTCCTUploadOperation.h"

@interface GDTCCTUploadOperation ()
@property(nonatomic, readonly) GDTCORTarget target;
@property(nonatomic, readonly) id<GDTCORStoragePromiseProtocol> storage;
@property(nonatomic, readonly) dispatch_queue_t uploadQueue;

@property(nonatomic, readwrite, getter=isExecuting) BOOL executing;
@end

@implementation GDTCCTUploadOperation

@synthesize executing = _executing;

- (instancetype)initWithTarget:(GDTCORTarget)target queue:(dispatch_queue_t)uploadQueue storage:(id<GDTCORStoragePromiseProtocol>)storage {
  self = [super init];

  if (self) {
    _target = target;
    _storage = storage;
    _uploadQueue = uploadQueue;
  }

  return self;
}

- (BOOL)isAsynchronous {
  return YES;
}

- (void)setExecuting:(BOOL)executing {
  
}

@end
