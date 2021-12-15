//
//  RealTimeConfigStream.h
//  Pods
//
//  Created by Quan Pham on 12/13/21.
//

#ifndef RealTimeConfigStream_h
#define RealTimeConfigStream_h

#import <Foundation/Foundation.h>
#import "Generated/RealTimeRemoteConfig.pbrpc.h"
#import <UIKit/UIKit.h>

@interface RealTimeConfigStream : UIViewController <GRPCProtoResponseHandler> {
}

@property(weak, nonatomic) IBOutlet UILabel *outputLabel;
- (instancetype) initWithClass:(RCNConfigFetch *) configFetch;
- (void)setRealTimeDelegateCallback:(id)realTimeDelegate;
- (void)removeRealTimeDelegateCallback;

@end

// Callback delegate
@interface NSObject(RealTimeDelegateMethods)
- (void)handleRealTimeConfigFetch: (RealTimeConfigStream *)realTimeStream;

@end

#endif /* RealTimeConfigStream_h */
