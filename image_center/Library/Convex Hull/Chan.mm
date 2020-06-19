//
//  Chan.m
//  image_center
//
//  Created by Владимир Костин on 10.05.2020.
//  Copyright © 2020 kostin. All rights reserved.
//

#import "common.h"
#import <opencv2/opencv.hpp>

static int RIGHT_TURN = -1;  // CW
static int LEFT_TURN = 1;  // CCW
static int COLLINEAR = 0;  // Collinear

/*
    Returns the index of the cv::Point to which the tangent is drawn from cv::Point p.
    Uses a modified Binary Search Algorithm to yield tangent in O(log n) complexity
    @param v: vector of objects of class cv::Points representing the hull aka the vector of hull cv::Points
    @param p: Object of class cv::Point from where tangent needs to be drawn
*/
int tangent(std::vector<cv::Point> v,cv::Point p){
    int l = 0;
    int r = static_cast<int>(v.size());
    int l_before = orientation(p, v[0], v[v.size()-1]);
    int l_after = orientation(p, v[0], v[(l + 1) % v.size()]);
    while (l < r){
        int c = ((l + r)>>1);
        int c_before = orientation(p, v[c], v[(c - 1) % v.size()]);
        int c_after = orientation(p, v[c], v[(c + 1) % v.size()]);
        int c_side = orientation(p, v[l], v[c]);
        if (c_before != RIGHT_TURN and c_after != RIGHT_TURN)
            return c;
        else if ((c_side == LEFT_TURN) && (l_after == RIGHT_TURN || l_before == l_after)) {
            r = c;
        } else {
            if (c_side == RIGHT_TURN && c_before == RIGHT_TURN)
                r = c;
            else
                l = c + 1;
        }
        l_before = -c_after;
        l_after = orientation(p, v[l], v[(l + 1) % v.size()]);
    }
    return l;
}

/*
    Returns the pair of integers representing the Hull # and the cv::Point in that Hull which is the extreme amongst all given Hull cv::Points
    @param hulls: Vector containing the hull cv::Points for various hulls stored as individual vectors.
*/
std::pair<int,int> extreme_hullpt_pair(std::vector<std::vector<cv::Point> >& hulls){
    int h= 0,p= 0;
    for (int i=0; i<hulls.size(); ++i){
        int min_index=0, min_y = hulls[i][0].y;
        for(int j=1; j< hulls[i].size(); ++j){
            if(hulls[i][j].y < min_y){
                min_y=hulls[i][j].y;
                min_index=j;
            }
        }
        if(hulls[i][min_index].y < hulls[h][p].y){
            h=i;
            p=min_index;
        }
    }
    return std::make_pair(h,p);
}

/*
    Returns the pair of integers representing the Hull # and the cv::Point in that Hull to which the cv::Point lcv::Point will be joined
    @param hulls: Vector containing the hull cv::Points for various hulls stored as individual vectors.
    @param lcv::Point: Pair of the Hull # and the leftmost extreme cv::Point contained in that hull, amongst all the obtained hulls
*/
std::pair<int,int> next_hullpt_pair(std::vector<std::vector<cv::Point> >& hulls, std::pair<int,int> lPoint){
    cv::Point p = hulls[lPoint.first][lPoint.second];
    std::pair<int,int> next = std::make_pair(lPoint.first, (lPoint.second + 1) % hulls[lPoint.first].size());
    for (int h=0; h< hulls.size(); h++){
        if(h != lPoint.first){
            int s= tangent(hulls[h],p);
            cv::Point q= hulls[next.first][next.second];
            cv::Point r= hulls[h][s];
            int t= orientation(p,q,r);
            if( t== RIGHT_TURN || (t==COLLINEAR) && dist(p,r)>dist(p,q))
                next = std::make_pair(h,s);
        }
    }
    return next;
}

/*
    Implementation of Chan's Algorithm to compute Convex Hull in O(nlogh) complexity
*/
std::vector<cv::Point> chansalgorithm(std::vector<cv::Point> v){
    std::vector<cv::Point> output;
    for(int t=0; t< v.size(); ++t){
        for(int m=1; m< (1<<(1<<t)); ++m){
            std::vector<std::vector<cv::Point> > hulls;
            for(int i=0;i<v.size();i=i+m){
                std::vector<cv::Point> chunk;
                if(v.begin()+i+m <= v.end())
                    chunk.assign(v.begin()+i,v.begin()+i+m);
                else
                    chunk.assign(v.begin()+i,v.end());
                hulls.push_back(GrahamScan(chunk));
            }
            std::vector<std::pair<int,int> > hull;
            hull.push_back(extreme_hullpt_pair(hulls));
            for(int i=0; i<m; ++i){
                std::pair<int,int> p = next_hullpt_pair(hulls,hull[hull.size()-1]);
                if(p==hull[0]){
                    for(int j=0; j<hull.size();++j){
                        output.push_back(hulls[hull[j].first][hull[j].second]);
                    }
                    return output;
                }
                hull.push_back(p);
            }
        }
    }
    return output;
}
