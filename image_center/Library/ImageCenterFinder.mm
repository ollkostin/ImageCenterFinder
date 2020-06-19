//
//  OpenCV.mm
//
//  Created by Владимир Костин on 18.05.2020.
//  Copyright © 2020 kostin. All rights reserved.
//

#import "OpenCVCommon.h"
#import "ImageCenterFinder.h"

static double EPS = 0.001;
static cv::Point zero = cv::Point(0, 0);
static cv::Mat kernel = cv::Mat::ones(3, 3, CV_32S);

static cv::Mat dilate(cv::Mat im) {
    cv::Mat morph;
    cv::morphologyEx(im, morph, cv::MORPH_DILATE, kernel);
    return morph;
}

static std::vector<cv::Point> approximateContour(std::vector<cv::Point> contour) {
    double epsilon = EPS * cv::arcLength(contour, true);
    std::vector<cv::Point> approximatedContour;
    cv::approxPolyDP(contour, approximatedContour, epsilon, true);
    return approximatedContour;
}

static cv::Mat convertImage(cv::Mat mat) {
    cv::Mat gray;
    cv::cvtColor(mat, gray, cv::COLOR_BGR2GRAY);

    cv::Mat canny;
    cv::Canny(gray, canny, 150.0, 200.0);

    cv::Mat bilateral;
    cv::bilateralFilter(canny, bilateral, 5, 75.0, 75.0);

    cv::Mat treshold;
    cv::adaptiveThreshold(bilateral, treshold, 255.0, cv::ADAPTIVE_THRESH_GAUSSIAN_C, cv::THRESH_BINARY, 7, 0.0);

    cv::Mat dilated = dilate(treshold);

    int h = dilated.rows;
    int w = dilated.cols;

    cv::Mat mask = cv::Mat::zeros(h + 2.0, w + 2.0, CV_8U);

    cv::Mat floodfilled;
    dilated.copyTo(floodfilled);

    cv::Point seed(0.0, 0.0);

    cv::floodFill(floodfilled, mask, seed, cv::Scalar(255), 0, cv::Scalar(), cv::Scalar(), 4 | (255 << 8));

    cv::Mat bitwiseNot;
    cv::bitwise_not(floodfilled, bitwiseNot);

    cv::Mat result;
    cv::bitwise_or(dilated, bitwiseNot, result);

    return result;
}

@implementation ImageCenterFinder

static std::vector<cv::Point> findCenters(std::vector<std::vector<cv::Point> > &contours) {
    std::vector<cv::Point> centers;
    for (std::vector<cv::Point>::size_type i = 0; i != contours.size(); i++) {
        cv::Moments moments = cv::moments(approximateContour(contours.at(i)));
        if (moments.m00 != 0) {
            double x = double(moments.m10 / moments.m00);
            double y = double(moments.m01 / moments.m00);
            centers.push_back(cv::Point(x, y));
        }
    }
    return centers;
}

static std::vector<std::vector<cv::Point>> findContours(const cv::Mat &mat) {
    std::vector<std::vector<cv::Point>> contours;
    cv::findContours(mat, contours, cv::RETR_TREE, cv::CHAIN_APPROX_SIMPLE, zero);
    return contours;
}

static std::vector<cv::Point> findHull(const std::vector<cv::Point> &centers) {
    std::vector<cv::Point> hull;
    cv::convexHull(centers, hull);
    return hull;
}

+ (nonnull UIImage *)process:(nonnull UIImage *)image {
    cv::Mat mat;
    UIImageToMat(image, mat, CV_8UC4);

    cv::Mat processed = convertImage(mat);

    std::vector<std::vector<cv::Point> > contours = findContours(processed);

    if (contours.size() > 0) {

        std::vector<cv::Point> centers = findCenters(contours);

        if (centers.size() > 0) {
            NSDate *methodStart = [NSDate date];
            std::vector<cv::Point> hull = findHull(centers);
            NSDate *methodFinish = [NSDate date];
            NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
            NSLog(@"\n executionTime = %f", executionTime);

            if (!hull.empty()) {
                std::vector<std::vector<cv::Point>> hullWrapper;
                hullWrapper.push_back(hull);

                cv::Point mainCenter;
                cv::Moments moments = cv::moments(hull);
                if (moments.m00 != 0) {
                    int x = static_cast<int>(moments.m10 / moments.m00);
                    int y = static_cast<int>(moments.m01 / moments.m00);
                    mainCenter = cv::Point(x, y);

                    cv::drawContours(mat, hullWrapper, 0, cv::Scalar(255, 0, 255), 3);
                    cv::circle(mat, mainCenter, 7, cv::Scalar(255, 0, 255));
                    UIImage *result = MatToUIImage(mat);
                    return RestoreUIImageOrientation(result, image);
                }
            }
        }
    }
    return image;

}


@end
