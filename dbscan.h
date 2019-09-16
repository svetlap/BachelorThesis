#pragma once
#ifndef DBSCAN_H
#define DBSCAN_H

#include <vector>
#include <cmath>

#define UNCLASSIFIED -1
#define CORE_POINT 1
#define BORDER_POINT 2
#define NOISE -2
#define SUCCESS 0
#define FAILURE -3

using namespace std;

typedef struct Point_
{
	int x, y, z;  // X, Y, Z position
	int clusterID;  // clustered ID
}Point;

class DBSCAN {
public:
	DBSCAN(unsigned int minPts, float eps, vector<Point> points) {
		m_minPoints = minPts;
		m_epsilon = eps;
		m_points = points;
		m_pointSize = points.size();
	}
	~DBSCAN() {}

	int run();
	vector<int> calculateCluster(Point point);
	int expandCluster(Point point, int clusterID);
	inline double calculateDistance(Point pointCore, Point pointTarget);

	int getTotalPointSize() { return m_pointSize; }
	int getMinimumClusterSize() { return m_minPoints; }
	int getEpsilonSize() { return m_epsilon; }
	vector<Point> m_points;
private:
	unsigned int m_pointSize;
	unsigned int m_minPoints;
	int m_epsilon;
};

#endif // DBSCAN_H