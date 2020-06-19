//
// Created by Владимир Костин on 18.05.2020.
// Copyright (c) 2020 kostin. All rights reserved.
//

#import <opencv2/opencv.hpp>

#ifndef IMAGE_CENTER_COMMON_H
#define IMAGE_CENTER_COMMON_H

int compare(const void *vp1, const void *vp2);

int dist(cv::Point p1, cv::Point p2);

int orientation(cv::Point p, cv::Point q, cv::Point r);

std::vector<cv::Point> GrahamScan(std::vector<cv::Point> &points);


#endif //IMAGE_CENTER_COMMON_H
