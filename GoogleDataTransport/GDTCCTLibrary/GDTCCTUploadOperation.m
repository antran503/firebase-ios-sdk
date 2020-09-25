//
//  GDTCCTUploadOperation.m
//  GoogleDataTransport
//
//  Created by Maksym Malyhin on 2020-09-21.
//

#import "GoogleDataTransport/GDTCCTLibrary/GDTCCTUploadOperation.h"

#import <FBLPromises/FBLPromises.h>

#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCORConsoleLogger.h"
#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCOREvent.h"
#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCORPlatform.h"
#import "GoogleDataTransport/GDTCORLibrary/Public/GoogleDataTransport/GDTCORStorageProtocol.h"
#import "GoogleDataTransport/GDTCORLibrary/Private/GDTCORUploadBatch.h"

#import <nanopb/pb.h>
#import <nanopb/pb_decode.h>
#import <nanopb/pb_encode.h>

#import "GoogleDataTransport/GDTCCTLibrary/Private/GDTCCTCompressionHelper.h"
#import "GoogleDataTransport/GDTCCTLibrary/Private/GDTCCTNanopbHelpers.h"

#import "GoogleDataTransport/GDTCCTLibrary/Protogen/nanopb/cct.nanopb.h"

NS_ASSUME_NONNULL_BEGIN

#ifdef GDTCOR_VERSION
#define STR(x) STR_EXPAND(x)
#define STR_EXPAND(x) #x
static NSString *const kGDTCCTSupportSDKVersion = @STR(GDTCOR_VERSION);
#else
static NSString *const kGDTCCTSupportSDKVersion = @"UNKNOWN";
#endif  // GDTCOR_VERSION

static const NSTimeInterval kBatchExpirationTimeout = 600;

@interface GDTCCTUploadURLTaskResult : NSObject
@property(nonatomic) NSNumber *batchID;
@property(nonatomic) NSURLResponse *response;
@property(nonatomic) NSData *data;
@end

@implementation GDTCCTUploadURLTaskResult
@end

@interface GDTCCTUploadOperation ()
@property(nonatomic, readonly) GDTCORTarget target;
@property(nonatomic, readonly) GDTCORUploadConditions conditions;
@property(nonatomic, readonly) NSURL *serverURL;
@property(nonatomic, readonly) id<GDTCORStoragePromiseProtocol> storage;
@property(nonatomic, readonly) dispatch_queue_t uploadQueue;
@property(nonatomic, readonly) NSURLSession *URLSession;
@property(nonatomic, readonly) id<GDTCCTUploadMetadataProvider> metadataProvider;

@property(nonatomic, readwrite, getter=isExecuting) BOOL executing;
@property(nonatomic, readwrite, getter=isFinished) BOOL finished;
@end

@implementation GDTCCTUploadOperation

@synthesize executing = _executing;
@synthesize finished = _finished;

- (instancetype)initWithTarget:(GDTCORTarget)target conditions:(GDTCORUploadConditions)conditions serverURL:(NSURL *)serverURL queue:(dispatch_queue_t)uploadQueue storage:(id<GDTCORStoragePromiseProtocol>)storage URLSession:(NSURLSession *)URLSession metadataProvider:(id<GDTCCTUploadMetadataProvider>)metadataProvider {
  self = [super init];

  if (self) {
    _target = target;
    _conditions = conditions;
    _serverURL = serverURL;
    _storage = storage;
    _uploadQueue = uploadQueue;
    _URLSession = URLSession;
  }

  return self;
}

# pragma mark - NSOperation methods

- (BOOL)isAsynchronous {
  return YES;
}

- (void)setExecuting:(BOOL)executing {

}

- (void)setFinished:(BOOL)finished {

}

- (void)startOperation {

}

- (void)finishOperation {

}

#pragma mark - Uploading

- (void)main {
  if (self.isCancelled) {
    return;
  }

  __block GDTCORBackgroundIdentifier backgroundTaskID = GDTCORBackgroundIdentifierInvalid;

  dispatch_block_t backgroundTaskCompletion = ^{
    // End the background task if there was one.
    if (backgroundTaskID != GDTCORBackgroundIdentifierInvalid) {
      [[GDTCORApplication sharedApplication] endBackgroundTask:backgroundTaskID];
      backgroundTaskID = GDTCORBackgroundIdentifierInvalid;
    }
  };

  backgroundTaskID = [[GDTCORApplication sharedApplication]
      beginBackgroundTaskWithName:@"GDTCCTUploader-upload"
                expirationHandler:^{
                  if (backgroundTaskID != GDTCORBackgroundIdentifierInvalid) {
                    // End the background task.
                    backgroundTaskCompletion();
                  }
                }];

  id<GDTCORStoragePromiseProtocol> storage = self.storage;

  // 1. Check if the conditions for the target are suitable.
  [self isReadyToUploadTarget:self.target conditions:self.conditions].
  thenOn(self.uploadQueue, ^id(id result) {
    // 2. Remove previously attempted batches
    return [storage removeAllBatchesForTarget:self.target deleteEvents:NO];
  })
  .thenOn(self.uploadQueue, ^id(id result) {
        // There may be a big amount of events stored, so creating a batch may be an
        // expensive operation.

        // 3. Do a lightweight check if there are any events for the target first to
        // finish early if there are no.
    return [storage hasEventsForTarget:self.target];
      })
  .validateOn(self.uploadQueue, ^BOOL(NSNumber *hasEvents) {
    // 4. Don't proceed if there are no events
    return hasEvents.boolValue;
  })
  .thenOn(self.uploadQueue, ^FBLPromise<GDTCORUploadBatch *> *(id result) {
    // 5. Fetch a batch of events for upload.
    GDTCORStorageEventSelector *eventSelector = [self eventSelectorTarget:self.target
                                                           withConditions:self.conditions];
    return [storage batchWithEventSelector:eventSelector
                           batchExpiration:[NSDate dateWithTimeIntervalSinceNow:kBatchExpirationTimeout]];
  });

}

- (FBLPromise<GDTCCTUploadURLTaskResult *> *)uploadBatch:(GDTCORUploadBatch *)batch {
//  NSNumber
  return [FBLPromise onQueue:self.uploadQueue async:^(FBLPromiseFulfillBlock  _Nonnull fulfill, FBLPromiseRejectBlock  _Nonnull reject) {

    NSURLRequest *request = [self URLRequestWithBatch:batch];
    GDTCORLogDebug(@"CTT: request containing %lu events created: %@", (unsigned long)batch.events.count,
                   request);

    NSURLSessionTask *task = [self.URLSession
        uploadTaskWithRequest:request
                     fromData:request.HTTPBody
            completionHandler:^(NSData *_Nullable data, NSURLResponse *_Nullable response,
                                NSError *_Nullable error) {
      // TODO:
//              completionHandler(batchID, eventsForDebug, data, response, error);
      if (error) {
        reject(error);
      } else {

      }
            }];
    GDTCORLogDebug(@"%@", @"CCT: The upload task is about to begin.");
    [task resume];

  }];
}



- (NSURLRequest *)URLRequestWithBatch:(GDTCORUploadBatch *)batch {
  NSData *requestProtoData = [self constructRequestProtoWithEvents:batch.events];
  NSData *gzippedData = [GDTCCTCompressionHelper gzippedData:requestProtoData];
  BOOL usingGzipData = gzippedData != nil && gzippedData.length < requestProtoData.length;
  NSData *dataToSend = usingGzipData ? gzippedData : requestProtoData;
  return [self constructRequestForTarget:self.target data:dataToSend];
}

- (BOOL)readyToUploadTarget:(GDTCORTarget)target conditions:(GDTCORUploadConditions)conditions {
  // Not ready to upload with no network connection.
  // TODO: Reconsider using reachability to prevent an upload attempt.
  // See https://developer.apple.com/videos/play/wwdc2019/712/ (49:40) for more details.
  if (conditions & GDTCORUploadConditionNoNetwork) {
    GDTCORLogDebug(@"%@", @"CCT: Not ready to upload without a network connection.");
    return NO;
  }

  // Upload events when there are with no additional conditions for kGDTCORTargetCSH.
  if (target == kGDTCORTargetCSH) {
    GDTCORLogDebug(@"%@", @"CCT: kGDTCORTargetCSH events are allowed to be "
                          @"uploaded straight away.");
    return YES;
  }

  if (target == kGDTCORTargetINT) {
    GDTCORLogDebug(@"%@", @"CCT: kGDTCORTargetINT events are allowed to be "
                          @"uploaded straight away.");
    return YES;
  }

  // Upload events with no additional conditions if high priority.
  if ((conditions & GDTCORUploadConditionHighPriority) == GDTCORUploadConditionHighPriority) {
    GDTCORLogDebug(@"%@", @"CCT: a high priority event is allowing an upload");
    return YES;
  }

  // Check next upload time for the target.
  BOOL isAfterNextUploadTime = YES;
  GDTCORClock *nextUploadTime = [self.metadataProvider nextUploadTimeForTarget:target];
  if (nextUploadTime) {
    isAfterNextUploadTime = [[GDTCORClock snapshot] isAfter:nextUploadTime];
  }

  if (isAfterNextUploadTime) {
    GDTCORLogDebug(@"CCT: can upload to target %ld because the request wait time has transpired",
                   (long)target);
  } else {
    GDTCORLogDebug(@"CCT: can't upload to target %ld because the backend asked to wait",
                   (long)target);
  }

  return isAfterNextUploadTime;
}

/** @return A resolved promise if is ready and a rejected promise if not. */
- (FBLPromise<NSNull *> *)isReadyToUploadTarget:(GDTCORTarget)target conditions:(GDTCORUploadConditions)conditions {
  FBLPromise<NSNull *> *promise = [FBLPromise pendingPromise];
  if ([self readyToUploadTarget:target conditions:conditions]) {
    [promise fulfill:[NSNull null]];
  } else {
    // TODO: Do we need a more comprehensive message here?
    [promise reject:[self genericRejectedPromiseErrorWithReason:@"Is not ready."]];
  }
  return promise;
}

// TODO: Move to a separate class/extension/file.
- (NSError *)genericRejectedPromiseErrorWithReason:(NSString *)reason {
  return [NSError errorWithDomain:@"GDTCCTUploader" code:-1 userInfo:@{ NSLocalizedFailureReasonErrorKey : reason }];
}

/** */
- (GDTCORStorageEventSelector *)eventSelectorTarget:(GDTCORTarget)target
                                              withConditions:(GDTCORUploadConditions)conditions {
  if ((conditions & GDTCORUploadConditionHighPriority) == GDTCORUploadConditionHighPriority) {
    return [GDTCORStorageEventSelector eventSelectorForTarget:target];
  }
  NSMutableSet<NSNumber *> *qosTiers = [[NSMutableSet alloc] init];
  if (conditions & GDTCORUploadConditionWifiData) {
    [qosTiers addObjectsFromArray:@[
      @(GDTCOREventQoSFast), @(GDTCOREventQoSWifiOnly), @(GDTCOREventQosDefault),
      @(GDTCOREventQoSTelemetry), @(GDTCOREventQoSUnknown)
    ]];
  }
  if (conditions & GDTCORUploadConditionMobileData) {
    [qosTiers addObjectsFromArray:@[ @(GDTCOREventQoSFast), @(GDTCOREventQosDefault) ]];
  }

  return [[GDTCORStorageEventSelector alloc] initWithTarget:target
                                                   eventIDs:nil
                                                 mappingIDs:nil
                                                   qosTiers:qosTiers];
}

/** Constructs data given an upload package.
 *
 * @param events The events used to construct the request proto bytes.
 * @return Proto bytes representing a gdt_cct_LogRequest object.
 */
- (nonnull NSData *)constructRequestProtoWithEvents:(NSSet<GDTCOREvent *> *)events {
  // Segment the log events by log type.
  NSMutableDictionary<NSString *, NSMutableSet<GDTCOREvent *> *> *logMappingIDToLogSet =
      [[NSMutableDictionary alloc] init];
  [events enumerateObjectsUsingBlock:^(GDTCOREvent *_Nonnull event, BOOL *_Nonnull stop) {
    NSMutableSet *logSet = logMappingIDToLogSet[event.mappingID];
    logSet = logSet ? logSet : [[NSMutableSet alloc] init];
    [logSet addObject:event];
    logMappingIDToLogSet[event.mappingID] = logSet;
  }];

  gdt_cct_BatchedLogRequest batchedLogRequest =
      GDTCCTConstructBatchedLogRequest(logMappingIDToLogSet);

  NSData *data = GDTCCTEncodeBatchedLogRequest(&batchedLogRequest);
  pb_release(gdt_cct_BatchedLogRequest_fields, &batchedLogRequest);
  return data ? data : [[NSData alloc] init];
}

/** Constructs a request to FLL given a URL and request body data.
 *
 * @param target The target backend to send the request to.
 * @param data The request body data.
 * @return A new NSURLRequest ready to be sent to FLL.
 */
- (nullable NSURLRequest *)constructRequestForTarget:(GDTCORTarget)target data:(NSData *)data {
  if (data == nil || data.length == 0) {
    GDTCORLogDebug(@"There was no data to construct a request for target %ld.", (long)target);
    return nil;
  }

  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.serverURL];
  NSString *targetString;
  switch (target) {
    case kGDTCORTargetCCT:
      targetString = @"cct";
      break;

    case kGDTCORTargetFLL:
      targetString = @"fll";
      break;

    case kGDTCORTargetCSH:
      targetString = @"csh";
      break;
    case kGDTCORTargetINT:
      targetString = @"int";
      break;

    default:
      targetString = @"unknown";
      break;
  }
  NSString *userAgent =
      [NSString stringWithFormat:@"datatransport/%@ %@support/%@ apple/", kGDTCORVersion,
                                 targetString, kGDTCCTSupportSDKVersion];
  if (target == kGDTCORTargetFLL || target == kGDTCORTargetCSH) {
    [request setValue:[self FLLAndCSHandINTAPIKey] forHTTPHeaderField:@"X-Goog-Api-Key"];
  }

  if (target == kGDTCORTargetINT) {
    [request setValue:[self FLLAndCSHandINTAPIKey] forHTTPHeaderField:@"X-Goog-Api-Key"];
  }

  if ([GDTCCTCompressionHelper isGzipped:data]) {
    [request setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
  }
  [request setValue:@"application/x-protobuf" forHTTPHeaderField:@"Content-Type"];
  [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
  [request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
  request.HTTPMethod = @"POST";
  [request setHTTPBody:data];
  return request;
}

#pragma mark - Keys

- (NSString *)FLLAndCSHandINTAPIKey {
  static NSString *defaultServerKey;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    // These strings should be interleaved to construct the real key.
    const char *p1 = "AzSBG0honD6A-PxV5nBc";
    const char *p2 = "Iay44Iwtu2vV0AOrz1C";
    const char defaultKey[40] = {p1[0],  p2[0],  p1[1],  p2[1],  p1[2],  p2[2],  p1[3],  p2[3],
                                 p1[4],  p2[4],  p1[5],  p2[5],  p1[6],  p2[6],  p1[7],  p2[7],
                                 p1[8],  p2[8],  p1[9],  p2[9],  p1[10], p2[10], p1[11], p2[11],
                                 p1[12], p2[12], p1[13], p2[13], p1[14], p2[14], p1[15], p2[15],
                                 p1[16], p2[16], p1[17], p2[17], p1[18], p2[18], p1[19], '\0'};
    defaultServerKey = [NSString stringWithUTF8String:defaultKey];
  });
  return defaultServerKey;
}

@end

NS_ASSUME_NONNULL_END
