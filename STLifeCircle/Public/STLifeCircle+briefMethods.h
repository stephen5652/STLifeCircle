//
//  STLifeCircle+briefMethods.h
//  STLifeCircle
//
//  Created by stephen.chen on 2021/12/7.
//

#import "STLifeCircle.h"

#import <STAnnotation/STAnnotationHeader.h>

NS_ASSUME_NONNULL_BEGIN

#if defined(__cplusplus)
extern "C" {
#endif

@interface STLifeCircle (briefMethods)
/**
 获取 STLifeCircle 单例
 */
STLifeCircle* STModuleLifeCircleInstance(void);

/**
 托管组件
 
 @param moduleInstance 组件实例
 */
void STModuleLifeCollocation(__kindof NSObject <UIApplicationDelegate> *moduleInstance);

/**
 托管组件
 
 @param moduleInstance 组件实例
 @param level 组件运行优先级 界别越高，越优先运行【一定会高于宿主App】
 */
void STModuleLifeCollocationWitLevel(__kindof NSObject <UIApplicationDelegate> *moduleInstance, NSInteger level);
@end

#if defined(__cplusplus)
}
#endif

NS_ASSUME_NONNULL_END
