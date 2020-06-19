//
// Created by Владимир Костин on 10.06.2020.
// Copyright (c) 2020 kostin. All rights reserved.
//

#import "OpenCVCommon.h"
#include "CameraMovementChecker.h"

static float DESCRIPTOR_MATCH = 0.6f;
static cv::Ptr<cv::DescriptorExtractor> CV_ORB = cv::ORB::create();
static cv::BFMatcher CV_BF_MATCHER = cv::BFMatcher(cv::NORM_L2, true);

static Boolean areDescriptorsMatch(cv::Mat curMat, cv::Mat prevMat) {
    cv::Mat prevDescriptors;
    cv::Mat curDescriptors;

    cv::Mat mask;

    std::vector<cv::KeyPoint> keypoints;

    CV_ORB->detectAndCompute(prevMat, mask, keypoints, prevDescriptors);

    CV_ORB->detectAndCompute(curMat, mask, keypoints, curDescriptors);

    std::vector<cv::DMatch> matches;
    CV_BF_MATCHER.match(curDescriptors, prevDescriptors, matches);

    float percentOfMatch = float(matches.size() / (curDescriptors.cols * curDescriptors.rows));
    Boolean result = percentOfMatch < DESCRIPTOR_MATCH;
    return result;
}

static cv::Mat toGrayMat(UIImage *img) {
    cv::Mat mat;
    UIImageToMat(img, mat, CV_8UC4);

    cv::Mat gray;
    cv::cvtColor(mat, gray, cv::COLOR_BGR2GRAY);
    return gray;
}

@implementation CameraMovementChecker

+ (Boolean)cameraMoved:(UIImage *)image prevImage:(UIImage *)prev {
    if (!prev) {
        return true;
    }
    cv::Mat prevMat = toGrayMat(prev);
    cv::Mat curMat = toGrayMat(image);
    return areDescriptorsMatch(curMat, prevMat);
}

@end
