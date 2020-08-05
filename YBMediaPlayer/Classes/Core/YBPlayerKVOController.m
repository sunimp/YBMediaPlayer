//
//  YBPlayerKVOController.m
//  YiBanClient
//
//  Created by Sun on 2019/12/25.
//  Copyright © 2019 Qing Class. All rights reserved.
//


#import "YBPlayerKVOController.h"

@interface YBKVOEntry : NSObject
@property (nonatomic, weak)   NSObject *observer;
@property (nonatomic, strong) NSString *keyPath;

@end

@implementation YBKVOEntry
@synthesize observer;
@synthesize keyPath;

@end

@interface YBPlayerKVOController ()
@property (nonatomic, weak) NSObject *target;
@property (nonatomic, strong) NSMutableArray *observerArray;

@end

@implementation YBPlayerKVOController

- (instancetype)initWithTarget:(NSObject *)target {
    self = [super init];
    if (self) {
        _target = target;
        _observerArray = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)safelyAddObserver:(NSObject *)observer
               forKeyPath:(NSString *)keyPath
                  options:(NSKeyValueObservingOptions)options
                  context:(void *)context {
    NSObject *target = _target;
    if (target == nil) return;
    
    BOOL removed = [self removeEntryOfObserver:observer forKeyPath:keyPath];
    if (removed) {
        // duplicated register
        NSLog(@"duplicated observer");
    }
    
    @try {
        [target addObserver:observer
                 forKeyPath:keyPath
                    options:options
                    context:context];
        
        YBKVOEntry *entry = [[YBKVOEntry alloc] init];
        entry.observer = observer;
        entry.keyPath  = keyPath;
        [_observerArray addObject:entry];
    } @catch (NSException *e) {
        NSLog(@"YBKVO: failed to add observer for %@\n", keyPath);
    }
}

- (void)safelyRemoveObserver:(NSObject *)observer
                  forKeyPath:(NSString *)keyPath {
    NSObject *target = _target;
    if (target == nil) return;
    
    BOOL removed = [self removeEntryOfObserver:observer forKeyPath:keyPath];
    if (removed) {
        // duplicated register
        NSLog(@"duplicated observer");
    }
    
    @try {
        if (removed) {
            [target removeObserver:observer
                        forKeyPath:keyPath];
        }
    } @catch (NSException *e) {
        NSLog(@"YBKVO: failed to remove observer for %@\n", keyPath);
    }
}

- (void)safelyRemoveAllObservers {
    __block NSObject *target = _target;
    if (target == nil) return;
    [_observerArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        YBKVOEntry *entry = obj;
        if (entry == nil) return;
        NSObject *observer = entry.observer;
        if (observer == nil) return;
        @try {
            [target removeObserver:observer
                        forKeyPath:entry.keyPath];
        } @catch (NSException *e) {
            NSLog(@"YBKVO: failed to remove observer for %@\n", entry.keyPath);
        }
    }];
    
    [_observerArray removeAllObjects];
}

- (BOOL)removeEntryOfObserver:(NSObject *)observer
                   forKeyPath:(NSString *)keyPath {
    __block NSInteger foundIndex = -1;
    [_observerArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        YBKVOEntry *entry = (YBKVOEntry *)obj;
        if (entry.observer == observer &&
            [entry.keyPath isEqualToString:keyPath]) {
            foundIndex = idx;
            *stop = YES;
        }
    }];
    
    if (foundIndex >= 0) {
        [_observerArray removeObjectAtIndex:foundIndex];
        return YES;
    }
    return NO;
}

@end
