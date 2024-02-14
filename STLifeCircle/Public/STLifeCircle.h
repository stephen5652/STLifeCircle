//
//  STLifeCircle.h
//  Pods
//
//  Created by stephen.chen on 2021/12/7.
//

#import <UIKit/UIApplication.h>

NS_ASSUME_NONNULL_BEGIN

@protocol STLifeCircleRegisterProtocol <NSObject>
/**
 托管app事件触发

 @discussion 用以在此事件中托管业务模块的生命周期事件
 */
+ (void)stModuleLifeRegisterExecute;
@end


/**
 UIApplicationDelegate 协议的扩展
 
 @discussion 在 UIApplicationDelegate 的周期事件基础上，追加一部分扩展事件，用以满足组件化的特殊需求
 */
@protocol STApplicationDelegateExtension <UIApplicationDelegate>
@optional
/**
 applicateion delegate 将要执行以下方法
 
 @discussion applicateion delegate 将要完成加载
 @code
 application:WillFinishLaunchingWithOptions:
 @endcode
 appDelegate 将要开始执行上面这个方法.
 
 注意:
 
 1. 此时系统application 还没有收到上面方法的回调.
 
 2. 此方法的执行顺序与其他生命周期方法有差异.
 
 3. 主app优先执行， 子app按照配置的优先级，从高到低执行.
 
 4. 用户可以在此处完成一些自己的个性化操作, 比如：加载字体，文本等
 */
- (void)application:(UIApplication *)application stBeforeWillFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions;

/**
 applicateion delegate 将要加载完成
 
 @discussion applicateion delegate 将要加载完成
 @code
 application:didFinishLaunchingWithOptions:
 @endcode
 appDelegate 将要执行完上面这个方法
 
 注意：
 
 1.此时主app和各个子app已经执行完成上面方法.
 
 2.此时系统application 还没有收到上面方法的回调，即主window已完成配置，但是还没有加载.
 
 3.子app按照优先级，从高到低依次调用该方法，主app最后执行改方法.
 
 4.用户可以在此处完成一些自己的个性化操作, 比如：配置三方平台等
 */
- (void)application:(UIApplication *)application stAfterDidFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions;
@end

/**
 App 托管类【单例】
 
 @discussion 此类是个单例， 会替代main函数设置的 appDelegate 成为Application的delegate, 并持有项目设置的appDelegate， 对生命周期事件进行分发。
 */
@interface STLifeCircle : NSObject
+ (instancetype)shareInstance;

/**
 打开生命周期事件转发的log
 
 @param openFlag 打开标识
 */
+ (void)openDebugLog:(BOOL)openFlag;

/**
 输出被托管的模块
 
 @return 被托管的所有模块.
 */
+ (NSArray<__kindof NSObject<UIApplicationDelegate> *> *)allCollocatedModules;

/**
 输出被托管的模块
 
 @return 被托管的所有模块.
 */
+ (NSDictionary<NSNumber *, NSArray<NSObject<UIApplicationDelegate> *> *> *)allCollocatedModulesDict;

/**
 获取宿主AppDelegate
 
 @return 宿主AppDelegate.
 */
+ (__kindof NSObject<UIApplicationDelegate> *)mainAppDelegate;

/**
 获取子模块appdelegate
 
 @param cls 子模块appdelegate的类
 @return 子模块appdelegagte.
 */
+ (__kindof NSObject<UIApplicationDelegate> *)subAppDelegateWithClass:(Class)cls;

/**
 * 托管子模块
 * @param moduleApp 模块生命周期类
 * */
- (void)stCollocationSubAppModule:(NSObject <UIApplicationDelegate> *)moduleApp;

/**
 * 托管子模块
 * @param moduleApp 模块生命周期类
 * @param level 级别 级别越高，越优先运行 【优先级一定会高于宿主App】
 * */
- (void)stCollocationSubAppModule:(NSObject <UIApplicationDelegate> *)moduleApp appLevel:(NSInteger)level;
@end

NS_ASSUME_NONNULL_END
