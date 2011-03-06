//
//  WFSparseTimer.m
//
//  Created by Jesper on 2011-03-06.
//
//  This contents of this file is placed in the public domain.
//  No rights are reserved, asserted or exercised.
//  For more information, see:
//    http://creativecommons.org/publicdomain/zero/1.0/
//

#import "WFSparseTimer.h"

//#define WFSparseTimerTracing  1

@implementation WFSparseTimer

- (id)initWithDispatchQueue:(dispatch_queue_t)aQueue
            atRoughInterval:(NSTimeInterval)interval
                      block:(dispatch_block_t)aBlock
{
    self = [super init];
    if (self) {
        blockQueue = aQueue;
        dispatch_retain(blockQueue);
        controlQueue = dispatch_queue_create([[NSString stringWithFormat:@"WFSparseTimer %p control queue", self] UTF8String], 0);
        source = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, controlQueue);
        dispatch_source_set_timer(source, dispatch_walltime(NULL, 0), interval * NSEC_PER_SEC, 0.005 * NSEC_PER_SEC);
        block = [aBlock copy];
        dispatch_source_set_event_handler(source, ^() {
            if (shouldFire) {
                shouldFire = NO;
#ifdef WFSparseTimerTracing
                NSLog(@"#%@ firing", self);
#endif
                dispatch_suspend(source);
                dispatch_sync(blockQueue, block);
            } else {
#ifdef WFSparseTimerTracing
                NSLog(@"#%@ not firing", self);
#endif
            }
        });
    }
    
    return self;
}

- (void)setNeedsFire {
    if (source == NULL)
        [NSException raise:@"WFSparseTimer made to fire after being invalidated." format:@""];
    
    dispatch_async(controlQueue, ^{
        if (source == NULL)
            return;
        
        if (!shouldFire) {
            dispatch_resume(source);
        }
    
        shouldFire = YES;
#ifdef WFSparseTimerTracing
        NSLog(@"#%@ needs to fire", self);
#endif
    });
}

- (void)toss {
    if (tossed) return;
    tossed = YES;
    shouldFire = NO;
    dispatch_async(controlQueue, ^{
#ifdef WFSparseTimerTracing
        NSLog(@"#%@ tossed", self);
#endif
        dispatch_source_cancel(source);
        dispatch_release(source);
        if (shouldFire) {
            dispatch_resume(controlQueue);
        }
        dispatch_release(controlQueue);
        dispatch_release(blockQueue);
        [block release];
        source = NULL;
    });
}

- (void)invalidate {
    [self toss];
    [self autorelease];
}

- (BOOL)isValid {
    return (source != NULL);
}

-(void)finalize {
    if (source != NULL) {
        [self toss];
    }
    [super finalize];
}

- (void)dealloc {
    if (source != NULL) {
        [self toss];
    }
    [super dealloc];
}

@end
