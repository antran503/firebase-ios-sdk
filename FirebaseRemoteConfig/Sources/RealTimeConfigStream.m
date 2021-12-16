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

@implementation RealTimeConfigStream {
    RCNConfigFetch *_configFetch;
    GRPCMutableCallOptions *_options;
    RTRCRealTimeRCService *_service;
    __weak id _realTimeDelegate;
    GRPCUnaryProtoCall *_streamCall;
}

- (instancetype) initWithClass: (RCNConfigFetch *)configFetch {
    self = [super init];
    
    if (self) {
        _configFetch = configFetch;
        
        // Set retry options
        _options = [[GRPCMutableCallOptions alloc] init];
        _options.transport = GRPCDefaultTransportImplList.core_insecure;
        _options.retryEnabled = TRUE;
        _options.retryCount = (NSUInteger)5;
        _options.keepaliveInterval = 100000;
        _options.connectMaxBackoff = 1000000;
        _options.connectInitialBackoff = 100;
        _options.retryFactor = 2.0;
        _options.minRetryInterval = 10;
        _options.maxRetryInterval = 100;
        
        _service = [[RTRCRealTimeRCService alloc] initWithHost:hostAddress callOptions:_options];
    }
    
    return  self;
}

- (dispatch_queue_t)dispatchQueue {
  return dispatch_get_main_queue();
}

- (void)startStream {
    RTRCOpenFetchInvalidationStreamRequest *request = [RTRCOpenFetchInvalidationStreamRequest message];
    request.lastKnownVersionNumber = 1;
    NSLog(@"Stream started");
    
    if (self->_streamCall == nil || self->_streamCall == NULL) {
        GRPCUnaryProtoCall *call = [_service openFetchInvalidationStreamWithMessage:request responseHandler:self callOptions:nil];
        self->_streamCall = call;
    }
    
    [self->_streamCall start];
}

- (void)pauseStream {
    if (self->_streamCall != NULL) {
        NSLog(@"Pausing stream");
        [self->_streamCall cancel];
        self->_streamCall = NULL;
    }
}

- (void)didReceiveProtoMessage:(GPBMessage *)message {
    RTRCOpenFetchInvalidationStreamResponse *response = (RTRCOpenFetchInvalidationStreamResponse *)message;
    if (response) {
        NSLog(@"Config invalidation message Received");
        // Fetch with expiration set to zero to ensure config is fetched.
        [self->_configFetch fetchConfigWithExpirationDuration: 0
            completionHandler: ^(FIRRemoteConfigFetchStatus status, NSError *error) {
                NSLog(@"Fetching new config");
                if (status == FIRRemoteConfigFetchStatusSuccess) {
                    if (self->_realTimeDelegate != NULL || self->_realTimeDelegate != nil) {
                        NSLog(@"Executing callback delegate");
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


