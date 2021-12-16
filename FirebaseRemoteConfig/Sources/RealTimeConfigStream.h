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

@interface RealTimeConfigStream : UIViewController <GRPCProtoResponseHandler>

@property(weak, nonatomic) IBOutlet UILabel *outputLabel;
@property(weak, nonatomic) id <RealTimeDelegateCallback> realTimeDelegate;

- (instancetype) initWithClass:(RCNConfigFetch *) configFetch;
- (void)setRealTimeDelegateCallback:(id)realTimeDelegate;
- (void)removeRealTimeDelegateCallback;
- (void)startStream;
- (void)pauseStream;

@end

#endif /* RealTimeConfigStream_h */
