//
//  Hull.m
//  image_center
//
//  Created by Владимир Костин on 03.05.2020.
//  Copyright © 2020 kostin. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import "common.h"

cv::Point zero = cv::Point(0, 0);

static int orientation0(cv::Point p, cv::Point q, cv::Point r) {
    int result = ((q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y));
    if (result == 0) {
        return 0; // Collinear
    } else if (result > 0) {
        return -1;
    } else {
        return 1;
    } // CW: -1 or CCW: 1
}

static int compare0(cv::Point p1, cv::Point p2) {
    int o = orientation0(zero, p1, p2);
    if (o == 0) {
        return dist(zero, p2) >= dist(zero, p1) ?  -1 : 1;
    } else if (o == 1) {
        return -1;
    } else {
        return 1;
    }
}

struct PointComparator {
    inline bool operator() (const cv::Point& p1, const cv::Point& p2) {
        return compare0(p1, p2) == 1;
    }
};

int quickselect0(std::vector<int> &ls, int index, int high, int low = 0, int depth = 0) {
    if (low == high) {
        return ls[low];
    }
    int pivot = (rand() % high) + low;
    int tmp = ls[low];
    ls[low] = ls[pivot];
    ls[pivot] = tmp;

    int cur = low;
    for (int i = low + 1; i < high + 1; i++) {
        if (ls[i] < ls[low]) {
            cur++;
            tmp = ls[cur];
            ls[i] = ls[cur];
            ls[cur] = tmp;
        }
    }
    tmp = ls[low];
    ls[cur] = ls[low];
    ls[low] = tmp;
    if (index < cur) {
        return quickselect0(ls, index, cur-1, low, depth + 1);
    } else if (index > cur) {
        return quickselect0(ls, index, high, cur+1, depth + 1);
    } else {
        return ls[cur];
    }
}

int quickselect(std::vector<int> ls, int index, int high, int low = 0, int depth = 0) {
    return quickselect0(ls, index, high, low, depth);
}

cv::Point quickselect0(std::vector<cv::Point> &ls, int index, int high, int low = 0, int depth = 0) {
    if (low == high) {
        return ls[low];
    }
    int pivot = (rand() % high) + low;
    cv::Point tmp = ls[low];
    ls[low] = ls[pivot];
    ls[pivot] = tmp;

    int cur = low;
    for (int i = low + 1; i < high + 1; i++) {
        if (compare0(ls[i], ls[low]) == -1) {
            cur++;
            tmp = ls[cur];
            ls[i] = ls[cur];
            ls[cur] = tmp;
        }
    }
    tmp = ls[low];
    ls[cur] = ls[low];
    ls[low] = tmp;
    if (index < cur) {
        return quickselect0(ls, index, cur-1, low, depth + 1);
    } else if (index > cur) {
        return quickselect0(ls, index, high, cur+1, depth + 1);
    } else {
        return ls[cur];
    }
}

cv::Point quickselect(std::vector<cv::Point> ls, int index, int high, int low = 0, int depth = 0) {
    return quickselect0(ls, index, high, low, depth);
}

static int y_kx(int y, int k, int x) {
    return y - k*x;
}

static std::pair<cv::Point, cv::Point> bridge(std::vector<cv::Point> &points, int verticalLine) {
    std::vector<cv::Point> candidates;
    if (points.size() == 2) {
        std::sort(points.begin(), points.end(), PointComparator());
        return std::pair<cv::Point, cv::Point>(points[0], points[1]);
    }
    std::vector<std::pair<cv::Point, cv::Point>> pairs;
    std::set<cv::Point, PointComparator> modifyS;
    std::copy(points.begin(), points.end(), std::inserter(modifyS, modifyS.end()));

    while (modifyS.size() >= 2) {
        cv::Point first = *modifyS.begin();
        modifyS.erase(first);
        cv::Point second = *modifyS.begin();
        modifyS.erase(second);
        std::vector<cv::Point> l;
        l.push_back(first);
        l.push_back(second);
        if (first == second) {
            printf("eq");
        }
        std::sort(l.begin(), l.end(), PointComparator());
        pairs.push_back(std::pair<cv::Point, cv::Point>(l[0], l[1]));
    }
    if (modifyS.size() == 1) {
        candidates.push_back(*modifyS.begin());
    }
    std::vector<int> slopes;
    for (std::vector<std::pair<cv::Point, cv::Point>>::iterator p = pairs.begin(); p != pairs.end(); p++) {
        cv::Point pi = p->first;
        cv::Point pj = p->second;
        if (pi.x == pj.x) {
            //pairs.erase(p);
            if (pi.y > pj.y) {
                candidates.push_back(pi);
            } else {
                candidates.push_back(pj);
            }
        } else {
            slopes.push_back((pi.y - pj.y) / (pi.x - pj.x));
        }
    }
    pairs.clear();
    int medianIndex = (int) slopes.size() / 2 - (slopes.size() % 2 == 0 ? 1 : 0);
    int medianSlope = quickselect(slopes, medianIndex, (int) slopes.size());
    std::vector<std::pair<cv::Point, cv::Point>> small;
    std::vector<std::pair<cv::Point, cv::Point>> eq;
    std::vector<std::pair<cv::Point, cv::Point>> large;
    for (int i = 0; i < slopes.size(); i++) {
        if (slopes[i] < medianSlope) {
            small.push_back(pairs[i]);
        } else if (slopes[i] == medianSlope) {
            eq.push_back(pairs[i]);
        } else {
            large.push_back(pairs[i]);
        }
    }

    cv::Point maxSlopePoint = *std::max_element(points.begin(), points.end(),
                                          [medianSlope](const cv::Point &lhs, const cv::Point &rhs) {
        return y_kx(lhs.y, medianSlope, lhs.x) > y_kx(rhs.y, medianSlope, rhs.x);
    });

    int maxSlope = y_kx(maxSlopePoint.y, medianSlope, maxSlopePoint.x);

    std::vector<cv::Point> maxSet;

    for (std::vector<cv::Point>::iterator p = points.begin(); p != points.end(); p++) {
        if (y_kx(p->y, medianSlope, p->x) == maxSlope) {
            maxSet.push_back(*p);
        }
    }


    cv::Point left = *(std::min_element(maxSet.begin(), maxSet.end(), PointComparator()));
    cv::Point right = *(std::max_element(maxSet.begin(), maxSet.end(), PointComparator()));

    if (left.x <= verticalLine && right.x > verticalLine) {
        return std::pair<cv::Point, cv::Point>(left, right);
    }
    if (right.x <= verticalLine) {
        for (std::vector<std::pair<cv::Point, cv::Point>>::iterator i = large.begin(); i != large.end(); i++) {
            candidates.push_back(i->second);
        }
        for (std::vector<std::pair<cv::Point, cv::Point>>::iterator i = eq.begin(); i != eq.end(); i++) {
            candidates.push_back(i->second);
        }
        for (std::vector<std::pair<cv::Point, cv::Point>>::iterator i = small.begin(); i != small.end(); i++) {
            candidates.push_back(i->first);
            candidates.push_back(i->second);
        }
    }
    if (left.x > verticalLine) {
        for (std::vector<std::pair<cv::Point, cv::Point>>::iterator i = small.begin(); i != small.end(); i++) {
            candidates.push_back(i->first);
        }
        for (std::vector<std::pair<cv::Point, cv::Point>>::iterator i = eq.begin(); i != eq.end(); i++) {
            candidates.push_back(i->first);
        }
        for (std::vector<std::pair<cv::Point, cv::Point>>::iterator i = large.begin(); i != large.end(); i++) {
            candidates.push_back(i->first);
            candidates.push_back(i->second);
        }
    }

    return bridge(candidates, verticalLine);
}

static std::vector<cv::Point> connect(cv::Point &lower, cv::Point &upper, std::vector<cv::Point> &points) {
    if (lower == upper) {
        std::vector<cv::Point> result;
        result.push_back(lower);
        return result;
    } else {
        cv::Point maxLeft = quickselect(points, (int)points.size() / 2 - 1,  (int) points.size());
        cv::Point minRight = quickselect(points, (int)points.size() / 2 , (int) points.size());
        std::pair<cv::Point, cv::Point> br = bridge(points, (maxLeft.x + minRight.x) / 2);
        cv::Point left = br.first;
        cv::Point right = br.second;
        std::vector<cv::Point> pointsLeft;
        pointsLeft.push_back(left);
        std::vector<cv::Point> pointsRight;
        pointsRight.push_back(right);
        for (std::vector<cv::Point>::iterator i = points.begin(); i != points.end(); i++) {
            if (i->x < left.x) {
                pointsLeft.push_back(*i);
            } else if (i->x > right.x) {
                pointsRight.push_back(*i);
            }
        }
        std::vector<cv::Point> l = connect(lower, left, pointsLeft);
        std::vector<cv::Point> r = connect(right, upper, pointsRight);
        std::vector<cv::Point> result;
        result.reserve(l.size() + r.size());
        result.insert(result.end(), l.begin(), l.end());
        result.insert(result.end(), r.begin(), r.end());
        l.clear();
        r.clear();
        return result;
    }
}

static std::vector<cv::Point> upperHull(std::vector<cv::Point> &points) {
    cv::Point lower = *std::min_element(points.begin(), points.end(), PointComparator());

    for (std::vector<cv::Point>::iterator i = points.begin(); i != points.end(); i++) {
        if (i->x == lower.x) {
            if (compare0(*i, lower) == -1) {
                lower = *i;
            }
        }
    }

    cv::Point upper = *std::max_element(points.begin(), points.end(), PointComparator());

    std::vector<cv::Point> newPoints;

    newPoints.push_back(lower);
    newPoints.push_back(upper);

    for (std::vector<cv::Point>::iterator i = points.begin(); i != points.end(); i++) {
        if (lower.x < i->x && i->x < upper.x) {
            newPoints.push_back(*i);
        }
    }

    return connect(lower, upper, newPoints);
}

static std::vector<cv::Point> flipped(std::vector<cv::Point> &points) {
    std::vector<cv::Point> result;
    for (std::vector<cv::Point>::iterator i = points.begin(); i != points.end(); i++) {
        result.push_back(cv::Point(-(i->x), -(i->y)));
    }
    return result;
}

std::vector<cv::Point> kirk(std::vector<cv::Point> points) {
    std::vector<cv::Point> hull;
    
    if (points.size() < 3) {
        return hull;
    }
    
    std::vector<cv::Point> upper = upperHull(points);
    std::vector<cv::Point> flippedUpper = flipped(points);
    std::vector<cv::Point> flippedLower = upperHull(flippedUpper);
    std::vector<cv::Point> lower = flipped(flippedLower);
    flippedLower.clear();
    flippedUpper.clear();


    hull.reserve(upper.size() + lower.size());
    hull.insert(hull.end(), upper.begin(), upper.end());
    hull.insert(hull.end(), lower.begin(), lower.end());

    return hull;
}


