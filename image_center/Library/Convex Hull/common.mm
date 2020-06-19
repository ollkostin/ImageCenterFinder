//
// Created by Владимир Костин on 18.05.2020.
// Copyright (c) 2020 kostin. All rights reserved.
//

#import <opencv2/opencv.hpp>

static cv::Point p0 = cv::Point(0, 0);

/*
    Returns square of the distance between the two cv::Point class objects
    @param p1: Object of class cv::Point aka first cv::Point
    @param p2: Object of class cv::Point aka second cv::Point
*/
int dist(cv::Point p1, cv::Point p2) {
    return (p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y);
}

/*
    Returns orientation of the line joining cv::Points p and q and line joining cv::Points q and r
    Returns -1 : CW orientation
            +1 : CCW orientation
            0 : Collinear
    @param p: Object of class cv::Point aka first cv::Point
    @param q: Object of class cv::Point aka second cv::Point
    @param r: Object of class cv::Point aka third cv::Point
*/
int orientation(cv::Point p, cv::Point q, cv::Point r) {
    int val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y);
    if (val == 0) return 0;  // Collinear
    return (val > 0) ? -1 : 1; // CW: -1 or CCW: 1
}

/*
    Constraint to find the outermost boundary of the cv::Points by checking if the cv::Points lie to the left otherwise adding the given cv::Point p
    Returns the Hull cv::Points
    @param v: Vector of all the cv::Points
    @param p: New cv::Point p which will be checked to be in the Hull cv::Points or not
*/
std::vector<cv::Point> keep_left(std::vector<cv::Point> &v, cv::Point p) {
    while (v.size() > 1 && orientation(v[v.size() - 2], v[v.size() - 1], p) != 1)
        v.pop_back();
    if (!v.size() || v[v.size() - 1] != p)
        v.push_back(p);
    return v;
}

/*
    Predicate function used while sorting the cv::Points using qsort() inbuilt function in C++
    @param p: Object of class cv::Point aka first cv::Point
    @param p: Object of class cv::Point aka second cv::Point
*/
int compare(const void *vp1, const void *vp2) {
    cv::Point *p1 = (cv::Point *) vp1;
    cv::Point *p2 = (cv::Point *) vp2;
    int orient = orientation(p0, *p1, *p2);
    if (orient == 0)
        return (dist(p0, *p2) >= dist(p0, *p1)) ? -1 : 1;
    return (orient == 1) ? -1 : 1;
}

/*
    Graham Scan algorithm to find convex hull from the given set of cv::Points
    @param cv::Points: List of the given cv::Points in the cluster (as obtained by Chan's Algorithm grouping)
    Returns the Hull cv::Points in a vector
*/
std::vector<cv::Point> GrahamScan(std::vector<cv::Point> &points) {
    if (points.size() <= 1)
        return points;
    qsort(&points[0], points.size(), sizeof(cv::Point), compare);
    std::vector<cv::Point> lower_hull;
    for (int i = 0; i < points.size(); ++i)
        lower_hull = keep_left(lower_hull, points[i]);
    reverse(points.begin(), points.end());
    std::vector<cv::Point> upper_hull;
    for (int i = 0; i < points.size(); ++i)
        upper_hull = keep_left(upper_hull, points[i]);
    for (int i = 1; i < upper_hull.size(); ++i)
        lower_hull.push_back(upper_hull[i]);
    return lower_hull;
}
