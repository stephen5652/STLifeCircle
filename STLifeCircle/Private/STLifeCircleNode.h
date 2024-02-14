//
//  STLifeCircleNode.h
//  STLifeCircle
//
//  Created by stephen.chen on 2023/1/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@protocol  UIApplicationDelegate;
/// 子app节点
@interface STLifeCircleNode: NSObject
- (void)storeOneSubApp:(NSObject<UIApplicationDelegate> *)subApp level:(NSInteger)level;
- (NSArray<NSObject<UIApplicationDelegate> *> *)allApps;
- (NSDictionary<NSNumber *, NSArray *> *) allAppDict;

- (NSObject<UIApplicationDelegate> *)subAppDelegateWithClass:(Class)cls;
@end

NS_ASSUME_NONNULL_END
