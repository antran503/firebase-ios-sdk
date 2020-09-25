//
//  GDTCCTUploadOperation.h
//  GoogleDataTransport
//
//  Created by Maksym Malyhin on 2020-09-21.
//

#import <Foundation/Foundation.h>

#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCORTargets.h"
#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCORUploader.h"

@class GDTCORClock;
@protocol GDTCORStoragePromiseProtocol;

NS_ASSUME_NONNULL_BEGIN

@protocol GDTCCTUploadMetadataProvider <NSObject>

- (nullable GDTCORClock *)nextUploadTimeForTarget:(GDTCORTarget)target;
- (void)setNextUploadTime:(nullable GDTCORClock *)time forTarget:(GDTCORTarget)target;

@end

@interface GDTCCTUploadOperation : NSOperation

- (instancetype)initWithTarget:(GDTCORTarget)target conditions:(GDTCORUploadConditions)conditions serverURL:(NSURL *)serverURL queue:(dispatch_queue_t)uploadQueue storage:(id<GDTCORStoragePromiseProtocol>)storage URLSession:(NSURLSession *)URLSession metadataProvider:(id<GDTCCTUploadMetadataProvider>)metadataProvider;

@end

NS_ASSUME_NONNULL_END
