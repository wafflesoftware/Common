//
//  WFSparseTimer.h
//
//  Created by Jesper on 2011-03-06.
//
//  This contents of this file is placed in the public domain.
//  No rights are reserved, asserted or exercised.
//  For more information, see:
//    http://creativecommons.org/publicdomain/zero/1.0/
//

#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>

@interface WFSparseTimer : NSObject {
@private
    dispatch_queue_t controlQueue;
    dispatch_queue_t blockQueue;
    dispatch_source_t source;
    dispatch_block_t block;
    BOOL shouldFire;
    BOOL tossed;
}
- (id)initWithDispatchQueue:(dispatch_queue_t)queue
            atRoughInterval:(NSTimeInterval)interval
                      block:(dispatch_block_t)block;

- (void)setNeedsFire;

// invalidate will, in accordance with NSTimer precedence, release the timer
- (void)invalidate;
- (BOOL)isValid;
@end
