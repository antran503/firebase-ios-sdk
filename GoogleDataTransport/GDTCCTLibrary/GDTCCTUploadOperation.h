//
//  GDTCCTUploadOperation.h
//  GoogleDataTransport
//
//  Created by Maksym Malyhin on 2020-09-21.
//

#import <Foundation/Foundation.h>

#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCORTargets.h"

@protocol GDTCORStoragePromiseProtocol;

NS_ASSUME_NONNULL_BEGIN

@interface GDTCCTUploadOperation : NSOperation

- (instancetype)initWithTarget:(GDTCORTarget)target queue:(dispatch_queue_t)uploadQueue storage:(id<GDTCORStoragePromiseProtocol>)storage;

@end

NS_ASSUME_NONNULL_END
