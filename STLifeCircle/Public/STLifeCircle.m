//
//  STLifeCircle.m
//  Pods
//
//  Created by stephen.chen on 2021/12/7.
//

#import "STLifeCircle.h"

#import "STLifeCircleNode.h"

#import "STLifeCircle+briefMethods.h"

#import <objc/runtime.h>
#import <STAnnotation/STAnnotationHeader.h>

@interface STLifeCircle ()<STApplicationDelegateExtension>
@property (nonatomic, strong) STLifeCircleNode *subAppContainer; ///< 子app存储器
@property(nonatomic, strong) NSObject <UIApplicationDelegate> *mainModule;
@property (nonatomic, strong) NSObject<UIApplicationDelegate> *sourceMainModule; ///< 被hook之前的appDelegate
@property (nonatomic, weak) UIApplication *sourceApplication; ///< 上次设定为代理的application
@property (nonatomic, assign) BOOL debugLogFlag; ///< 调试模式下，日志标识
@end

@implementation STLifeCircle

@STDirectRegist(){
    [STAnnotation stRegisterProtocol:@protocol(STLifeCircleRegisterProtocol)];
}

#pragma mark - life circle

+ (instancetype)shareInstance {
    return [self new];
}

+ (void)openDebugLog:(BOOL)openFlag {
    [STLifeCircle shareInstance].debugLogFlag = openFlag;
}

+ (NSArray<__kindof NSObject<UIApplicationDelegate> *> *)allCollocatedModules {
    return [[[self shareInstance] subAppContainer] allApps];
}

+ (NSDictionary<NSNumber *, NSArray<NSObject<UIApplicationDelegate> *> *> *)allCollocatedModulesDict {
    return [[[self shareInstance] subAppContainer] allAppDict];
}

+ (__kindof NSObject<UIApplicationDelegate> *)mainAppDelegate {
    return [STLifeCircle shareInstance].mainModule;
}

/**
 获取子模块appdelegate
 
 @param cls 子模块appdelegate的类
 @return 子模块appdelegagte.
 */
+ (__kindof NSObject<UIApplicationDelegate> *)subAppDelegateWithClass:(Class)cls {
    return [[[self shareInstance] subAppContainer] subAppDelegateWithClass: cls];
}

static STLifeCircle *imp;

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imp = [(STLifeCircle *) [super allocWithZone:zone] init_stModuleLife];
    });
    return imp;
}

- (instancetype)init {
    return imp;
}

- (instancetype)init_stModuleLife {
    if (self = [super init]) {
        self.subAppContainer = [STLifeCircleNode new];
    }
    return self;
}

#pragma mark - public methods

/**
 * 托管子模块
 * @param moduleApp 模块生命周期类
 * */
- (void)stCollocationSubAppModule:(NSObject <UIApplicationDelegate> *)moduleApp {
    [self stCollocationSubAppModule:moduleApp appLevel:0];
}

- (void)stCollocationSubAppModule:(NSObject <UIApplicationDelegate> *)moduleApp  appLevel:(NSInteger)level {
    if ([moduleApp.class isEqual:self.mainModule.class]) {
#ifdef DEBUG
        NSString *msg = [NSString stringWithFormat:@"宿主app实例不能设置为子模块: 宿主【%@】-- 子模块【%@】", self.mainModule, moduleApp];
        NSAssert(0, msg);
#endif
        return;
    }
    
    [self.subAppContainer storeOneSubApp:moduleApp level:level];
}

#pragma mark - work methods

- (void)initModulesConfig {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray<Class<STLifeCircleRegisterProtocol>> *clsArr = [STAnnotation stClassArrForProtocol:@protocol(STLifeCircleRegisterProtocol)];
        [clsArr enumerateObjectsUsingBlock:^(Class<STLifeCircleRegisterProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if([obj respondsToSelector:@selector(stModuleLifeRegisterExecute)]){
                [obj stModuleLifeRegisterExecute];
            }
        }];
    });
}

#pragma mark - forward message methods
- (struct objc_method_description) isProtocolMethod:(Protocol*)proto method:(SEL)sel {
    struct objc_method_description result = {};
    struct objc_method_description des_options = protocol_getMethodDescription(proto, sel, NO, YES);
    if (des_options.types){
        return des_options;
    }
    
    struct objc_method_description des_require = protocol_getMethodDescription(@protocol(STApplicationDelegateExtension), sel, YES, YES);
    if (des_require.types){
        return des_require;
    }
    
    return result;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    [self initModulesConfig];
    BOOL result = [super respondsToSelector:aSelector];
    if (result) return result;
    
    if ([self isProtocolMethod:@protocol(STApplicationDelegateExtension) method:aSelector].types) { //是STApplicationDelegateExtension 协议中的方法
        result = [self.mainModule respondsToSelector:aSelector];
        
        if (!result) {
            NSArray *values = [self.subAppContainer allApps];
            for (NSObject *one in values) {
                result = [one respondsToSelector:aSelector];
                if (result) break;
            }
        }
    }else{//不是UIApplicationDelegate 协议中的方法，需要判断是否是mainModule自身的方法
        result = [self.mainModule respondsToSelector:aSelector];
    }
    return result;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *result = nil;
    {
        /**
         1.此处在消息转发机制中不必要,因为调用本类实例的方法不会触发消息转发;
         2.但是此API是NSObject的公共方法, 有可能被主动调用,获取本类的某一方法的签名, 所以需要实现一下.
         */
        result = [super methodSignatureForSelector:aSelector];
        if (result) return result;
    }
    
    struct objc_method_description des = [self isProtocolMethod:@protocol(STApplicationDelegateExtension) method:aSelector];
    if (des.types) { //此方法是 UIApplicationDelegate 协议中的方法.
        result = [NSMethodSignature signatureWithObjCTypes:des.types];
        if(result) return result;
    }else if([self.mainModule respondsToSelector:aSelector]) { //主 app的方法
        result = [self.mainModule methodSignatureForSelector:aSelector];
        return result;
    }
    
    return nil;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    /*
     1. 为了适配iOS后期可能存在的 UIApplicationDelegate 协议的更新, 所以此处触发转发机制.
     2. UIApplicationDelegate 协议的方法,本类做了常用的带返回值的实现,并显式转发.
     3. 如果出问题, 此类需要补全其他带返回值的方法.
     */
    
    if (!self.mainModule){
#ifdef DEBUG
        NSString *msg = [NSString stringWithFormat:@"未设置主模块"];
        NSAssert(0, msg);
#endif
        return;
    }
    
    struct objc_method_description des = [self isProtocolMethod:@protocol(STApplicationDelegateExtension) method:anInvocation.selector];
    if (des.types) { //此方法是 UIApplicationDelegate 协议中的方法.
        NSArray<NSObject <UIApplicationDelegate> *> *values = [self.subAppContainer allApps];
        [values enumerateObjectsUsingBlock:^(NSObject <UIApplicationDelegate> *obj, NSUInteger idx, BOOL *stop) {
            if ([obj respondsToSelector:anInvocation.selector]){
#ifdef DEBUG
                if (self.debugLogFlag) {
                    NSLog(@"app生命周期事件:%@ - %@", obj, NSStringFromSelector(anInvocation.selector));
                }
#endif
                [anInvocation setTarget:obj];
                [anInvocation invoke];
            }
        }];
        
        if ([self.mainModule respondsToSelector:anInvocation.selector]) {
#ifdef DEBUG
            if (self.debugLogFlag) {
                NSLog(@"app生命周期事件:%@ - %@", self.mainModule, NSStringFromSelector(anInvocation.selector));
            }
#endif
            [anInvocation setTarget:self.mainModule];
            [anInvocation invoke];
        }
        
    }else if ([self.mainModule respondsToSelector:anInvocation.selector]){
        //此方法是主app独有的方法
        if ([self.mainModule respondsToSelector:anInvocation.selector]) {
#ifdef DEBUG
            if (self.debugLogFlag) {
                NSLog(@"宿主app事件:%@ - %@", self.mainModule, NSStringFromSelector(anInvocation.selector));
            }
#endif
            [anInvocation setTarget:self.mainModule];
            [anInvocation invoke];
        }
    }
}

#pragma mark - tool methods

- (BOOL)executeActionForBoolBackWitMainFirst:(BOOL) mainFirst action:(BOOL (^)(NSObject<UIApplicationDelegate> *obj))action {
#ifdef DEBUG
    if (!self.mainModule){
        NSString *msg = [NSString stringWithFormat:@"未设置主模块"];
        NSAssert(0, msg);
    }
#endif
    
    NSMutableArray<NSObject<UIApplicationDelegate> *> *arr = [NSMutableArray arrayWithArray: [self.subAppContainer allApps]];;
    if (YES == mainFirst){
        [arr insertObject:self.mainModule atIndex:0];
    }else{
        [arr addObject:self.mainModule];
    }
    
    __block BOOL result = NO;
    __block BOOL result_once = NO;
    
    for (NSObject<UIApplicationDelegate> *obj in arr) {
        if (action) {
            result_once = action(obj);
            result == NO ? result = result_once : 0;
        }
    }
    
    return result;
}

@end

#pragma mark - UIApplicationDelegate Method
@interface STLifeCircle(UIApplicationDelegateMethods)
@end
@implementation STLifeCircle(UIApplicationDelegateMethods)
- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(nullable NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions {
    
    [self application:application stBeforeWillFinishLaunchingWithOptions:launchOptions];
    
    SEL sel = _cmd;
    BOOL result =  [self executeActionForBoolBackWitMainFirst:YES action:^BOOL(NSObject<UIApplicationDelegate> *obj) {
        if ([obj respondsToSelector:sel]) {
            return [obj application:application willFinishLaunchingWithOptions:launchOptions];
        }else{
            return NO;
        }
    }];
    return result;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(nullable NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions {
    SEL sel = _cmd;
    BOOL result = [self executeActionForBoolBackWitMainFirst:NO action:^BOOL(NSObject<UIApplicationDelegate> *obj) {
        if ([obj respondsToSelector:sel]) {
            return [obj application:application didFinishLaunchingWithOptions:launchOptions];
        }else{
            return NO;
        }
    }];
    
    //此处追加了一个 stAfterDidFinishLaunchingWithOptions事件
    [self application:application stAfterDidFinishLaunchingWithOptions:launchOptions];
    return  result;
}

@end


@interface UIApplication (UIApplicationSTModuleLifeCircle)
@end

@implementation UIApplication (UIApplicationSTModuleLifeCircle)

+ (void)load {
    Method source = class_getInstanceMethod([self class], @selector(setDelegate:));
    Method hook = class_getInstanceMethod([self class], @selector(setDelegate_module_life:));
    
    method_exchangeImplementations(source, hook);
}

- (void)setDelegate_module_life:(id<UIApplicationDelegate>)delegate {
    /** 设置 app 代理 必须在主线程 */
    
    dispatch_block_t action = dispatch_block_create(0, ^{
        STLifeCircle *com = [STLifeCircle shareInstance];
        
        if (delegate == com) {
#ifdef DEBUG
        NSString *msg = [NSString stringWithFormat:@"不能设置【%@】为 application 的 delegate", com];
        NSAssert(0, msg);
#endif
            assert(0);
            return;
        }
        
        //此处是为了防止对 Application 做了继承，破坏了 UIApplication 的单利属性。
        if ([com.sourceApplication isMemberOfClass:[UIApplication class]]) {
            UIApplication *app = com.sourceApplication;
            com.sourceApplication = nil;
            app.delegate = nil;
        }
        
        
        if (delegate !=com) {
            com.sourceMainModule = delegate;
            com.mainModule = delegate;
            
            com.sourceApplication = self;
        }
        [self setDelegate_module_life:com];
    });
    
    if ([[NSThread currentThread] isMainThread]) {
        action();
    }else{
        dispatch_sync(dispatch_get_main_queue(), action);
    }
}

@end
