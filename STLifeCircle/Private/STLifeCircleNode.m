//
//  STLifeCircleNode.m
//  STLifeCircle
//
//  Created by stephen.chen on 2023/1/7.
//

#import "STLifeCircleNode.h"

@interface STLifeCircleNodeData: NSObject
@property (nonatomic, assign) NSInteger level; ///< 执行级别
@property (nonatomic, strong) NSObject<UIApplicationDelegate> * __nullable app; ///< 子app对象
@end

@implementation STLifeCircleNodeData
@end

@interface STLifeCircleNode()

@property (nonatomic, strong) NSMapTable<Class, NSObject<UIApplicationDelegate>*> *appMap; ///< 所有存储的数据

@property (nonatomic, strong) STLifeCircleNodeData *curData; ///< 当前数据
@property (nonatomic, strong) STLifeCircleNode * __nullable subNode; ///< 低于子app优先级的所有子节点
@end

@implementation STLifeCircleNode
- (instancetype)init {
    if (self = [super init]){
        self.appMap = [NSMapTable strongToStrongObjectsMapTable];
    }
    return self;
}

- (void)priSafeExecuteAction:(dispatch_block_t)action {
    [[NSThread currentThread] isMainThread] ? action() : dispatch_sync(dispatch_get_main_queue(), action);
}

- (void)storeOneSubApp:(NSObject<UIApplicationDelegate> *)subApp level:(NSInteger)level {
    if (![subApp conformsToProtocol:@protocol(UIApplicationDelegate)]) {
        NSString *msg = [NSString stringWithFormat:@"子模块未绑定协议:UIApplicationDelegate"];
        NSLog(@"%@", msg);
#ifdef DEBUG
        NSAssert(0, msg);
#endif
        return;
    }
    
    if([subApp isKindOfClass:NSObject.class]){
        if ([self.appMap objectForKey:subApp.class]) {
            NSString *msg = [NSString stringWithFormat:@"重复设置子模块：%@", subApp];
            NSLog(@"%@", msg);
#ifdef DEBUG
            NSAssert(0, msg);
#endif
            return;
        }
    }else{
        NSString *msg = [NSString stringWithFormat:@"子模块必须是NSObject类别：%@", subApp];
        NSLog(@"%@", msg);
#ifdef DEBUG
        NSAssert(0, msg);
#endif
        return;
    }
    
    
    
    STLifeCircleNodeData *data = [STLifeCircleNodeData new];
    data.level = level;
    data.app = subApp;
    [self priSafeExecuteAction:^{
        if (self.curData == nil){
            self.curData = data;
        }else{
            [self priStoreOneData:data];
        }
    }];
}

- (NSObject<UIApplicationDelegate> *)subAppDelegateWithClass:(Class)cls {
    return [self.appMap objectForKey:cls];
}

- (NSArray<NSObject<UIApplicationDelegate> *> *)allApps {
    __block NSArray<NSObject<UIApplicationDelegate> *> *result = nil;
    [self priSafeExecuteAction:^{
        result = [[self priAllApps] copy];
    }];
    return result;
}

- (NSDictionary<NSNumber *, NSArray *> *) allAppDict {
    __block NSDictionary<NSNumber *, NSArray *> *result = nil;
    [self priSafeExecuteAction:^{
        result = [[self priAllAppDict] copy];
    }];
    return result;
}

- (NSMutableArray<NSObject<UIApplicationDelegate> *> *)priAllApps{
    NSMutableArray *result = self.subNode ?  [self.subNode priAllApps] : [NSMutableArray new];
    [result insertObject:self.curData.app atIndex:0];
    return result;
}

- (NSMutableDictionary<NSNumber *, NSArray*> *) priAllAppDict{
    NSMutableDictionary * result = self.subNode ? [self.subNode priAllAppDict] : [NSMutableDictionary new];
   
    NSMutableArray *editArr = [NSMutableArray new];
    [editArr addObject:self.curData.app];
    
    NSNumber *lev = @(self.curData.level);
    NSArray *arr = [result objectForKey:lev];
    arr == nil ? 0 : [editArr addObjectsFromArray:arr];
    
    [result setObject:editArr.copy forKey:lev];
    return  result;
}

- (void)priStoreOneData:(STLifeCircleNodeData *)data{
    /*
     1. data级别小于等于当前级别，当前节点之后， 下个节点之前，插入新节点, 返回
     3. 下个节点处理这个数据
     */
    
    if (data.app == nil){
        return;
    }
    
    if (data.level > self.curData.level){ //当前节点之前插入节点
        STLifeCircleNode *n1 = [STLifeCircleNode new];
        n1.curData = self.curData;
        self.curData = data;
        
        n1.subNode = self.subNode;
        self.subNode = n1;
        [self.appMap setObject:data.app forKey:data.app.class];
    }else{
        if (self.subNode == nil){
            STLifeCircleNode *n1 = [STLifeCircleNode new];
            n1.curData = data;
            self.subNode = n1;
            [self.appMap setObject:data.app forKey:data.app.class];
            return;
        }
        
        [self.subNode priStoreOneData:data];
    }
}

@end
