//
// Created by Владимир Костин on 10.06.2020.
// Copyright (c) 2020 kostin. All rights reserved.
//



#ifndef IMAGE_CENTER_OPENCVCOMMON_H
#define IMAGE_CENTER_OPENCVCOMMON_H

#import <opencv2/opencv.hpp>
#import <UIKit/UIKit.h>

void UIImageToMat(UIImage *image, cv::Mat &mat, int type);

UIImage *MatToUIImage(cv::Mat &mat);

UIImage *RestoreUIImageOrientation(UIImage *processed, UIImage *original);


#endif //IMAGE_CENTER_OPENCVCOMMON_H
