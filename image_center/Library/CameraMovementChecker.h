//
// Created by Владимир Костин on 10.06.2020.
// Copyright (c) 2020 kostin. All rights reserved.
//

#ifndef IMAGE_CENTER_CAMERAMOVEMENTCHECKER_H
#define IMAGE_CENTER_CAMERAMOVEMENTCHECKER_H

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CameraMovementChecker : NSObject
+ (Boolean)cameraMoved:(UIImage *)image prevImage:(nullable UIImage *)prev;
@end

NS_ASSUME_NONNULL_END

#endif //IMAGE_CENTER_CAMERAMOVEMENTCHECKER_H
