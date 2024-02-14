//
//  STLifeCircle+briefMethods.m
//  STLifeCircle
//
//  Created by stephen.chen on 2021/12/7.
//

#import "STLifeCircle+briefMethods.h"

@implementation STLifeCircle (briefMethods)

STLifeCircle* STModuleLifeCircleInstance(void){
    return [STLifeCircle new];
}

void STModuleLifeCollocation(__kindof NSObject <UIApplicationDelegate> *moduleInstance) {
    STModuleLifeCollocationWitLevel(moduleInstance, 0);
}

void STModuleLifeCollocationWitLevel(__kindof NSObject <UIApplicationDelegate> *moduleInstance, NSInteger level) {
    [STModuleLifeCircleInstance() stCollocationSubAppModule:moduleInstance appLevel:level];
}
@end
