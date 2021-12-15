//
//  RealTimeConfigStream.m
//  FirebaseRemoteConfig
//
//  Created by Quan Pham on 12/13/21.
//

#import "Generated/RealTimeRemoteConfig.pbrpc.h"
#import <GRPCClient/GRPCTransport.h>
#import "RCNConfigFetch.h"
#import "RealTimeConfigStream.h"

static NSString *const hostAddress = @"localhost:50051";
static NSTimeInterval *const instantFetchTime = 0;

@implementation RealTimeConfigStream {
    RCNConfigFetch *_configFetch;
    RTRCRealTimeRCService *_service;
    id _realTimeDelegate;
    GRPCUnaryProtoCall *_streamCall;
}

- (instancetype) initWithClass: (RCNConfigFetch *)configFetch {
    self = [super init];
    
    if (self) {
        _configFetch = configFetch;
        
        // Set retry options
        GRPCMutableCallOptions *options = [[GRPCMutableCallOptions alloc] init];
        options.transport = GRPCDefaultTransportImplList.core_insecure;
        options.retryEnabled = TRUE;
        options.retryCount = (NSUInteger)5;
        options.keepaliveInterval = 100000;
        options.connectMaxBackoff = 1000000;
        options.connectInitialBackoff = 100;
        options.retryFactor = 2.0;
        options.minRetryInterval = 10;
        options.maxRetryInterval = 100;
        
        _service = [[RTRCRealTimeRCService alloc] initWithHost:hostAddress callOptions:options];
    }
    
    return  self;
}

- (dispatch_queue_t)dispatchQueue {
  return dispatch_get_main_queue();
}

- (void)startStream {
    RTRCOpenFetchInvalidationStreamRequest *request = [RTRCOpenFetchInvalidationStreamRequest message];
    request.lastKnownVersionNumber = 1;
    
    if (self->_streamCall == nil) {
        GRPCUnaryProtoCall *call = [_service openFetchInvalidationStreamWithMessage:request responseHandler:self callOptions:nil];
        self->_streamCall = call;
    }
    
    [self->_streamCall start];
}

- (void)pauseStream {
    if (self->_streamCall != NULL) {
        [self->_streamCall cancel];
    }
}

- (void)didReceiveProtoMessage:(GPBMessage *)message {
    RTRCOpenFetchInvalidationStreamResponse *response = (RTRCOpenFetchInvalidationStreamResponse *)message;
    if (response) {
        // Fetch
        [self->_configFetch fetchConfigWithExpirationDuration: *instantFetchTime
            completionHandler: ^(FIRRemoteConfigFetchStatus status, NSError *error) {
                if (status == FIRRemoteConfigFetchStatusSuccess) {
                    if (self->_realTimeDelegate != NULL) {
                        [self->_realTimeDelegate handleRealTimeConfigFetch:self];
                    }
                } else {
                    NSLog(@"Config not fetched");
                    NSLog(@"Error %@", error.localizedDescription);
                }
            }
        ];
    }
}

- (void)setRealTimeDelegateCallback:(id)realTimeDelegate {
    self->_realTimeDelegate = realTimeDelegate;
}

- (void)removeRealTimeDelegateCallback {
    self->_realTimeDelegate = NULL;
}

- (void)didCloseWithTrailingMetadata:(NSDictionary *)trailingMetadata error:(NSError *)error {
    if (error) {
        // Handle error
        NSLog(@"Stream Closed");
        NSLog(@"Error %@", error.localizedDescription);
    }
}

@end


