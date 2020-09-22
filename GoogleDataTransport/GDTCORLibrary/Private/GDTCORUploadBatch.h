//
//  GDTCORUploadBatch.h
//  GoogleDataTransport
//
//  Created by Maksym Malyhin on 2020-09-18.
//

#import <Foundation/Foundation.h>

@class GDTCOREvent;

NS_ASSUME_NONNULL_BEGIN

@interface GDTCORUploadBatch : NSObject

@property(nonatomic, readonly) NSNumber *batchID;
@property(nonatomic, readonly) NSSet<GDTCOREvent *> *events;

- (instancetype)initWithBatchID:(NSNumber *)batchID events:(NSSet<GDTCOREvent *> *)events;

@end

NS_ASSUME_NONNULL_END
