#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include "dbscan.h"

#define MINIMUM_POINTS 4     // minimum number of cluster
#define EPSILON (1)  // distance for clustering, meter^2

#define COLUMNS 1224
#define ROWS    720
#define OFFSET  (sizeof("data: ["))

struct imgPixel {
	char X;
	char Y;
	char flag;
};

uint32_t calculate_X(uint32_t position)
{
	return (position / COLUMNS);
}

uint32_t calculate_Y(uint32_t position)
{
	int take_X = calculate_X(position);
	if (take_X > 0)
		return (position % (take_X*COLUMNS));
	else
		return (position % COLUMNS);
}
/*
imgPixel construct_pixel(char X, char Y, char flag, int) {
	imgPixel temp_pixel = { X, Y, flag };
	return temp_pixel;
}*/

void printResults(vector<Point>& points, int num_points, const char *input_frame)
{
	static size_t counter = 0;

	std::string frame_name(input_frame);
	frame_name.append(std::to_string(counter));
	frame_name.append(".txt");
	FILE* fp = fopen(frame_name.c_str(), "w");

	size_t i = 0;
	while (i < num_points)
	{
		fprintf(fp,"%d %d %d %d\n",
			points[i].x,
			points[i].y, points[i].z,
			points[i].clusterID);
		++i;
	}

	fclose(fp);
	counter++;
}

int main(int argc, char *argv[])
{
	char X = 0;
	char Y = 0;
	char flag = 0;
	std::vector<Point> cluster_input;

	if (argc > 1)
	{
		std::ifstream input(argv[1]);

		for (std::string line; getline(input, line); )
		{
			if (line.find("data") != std::string::npos)
			{	
				size_t i = 0;

				for (; i < line.length(); i++)
				{
					if (isdigit(line[i]))
					{
						if (line[i] != '0')
						{
							uint32_t new_X = calculate_X((i - OFFSET) / 3);
							uint32_t new_Y = calculate_Y((i - OFFSET) / 3);

							Point * point = (Point*)calloc(1, sizeof(Point));
							if (point != NULL)
							{
								point->x = new_X;
								point->y = new_Y;
								point->z = line[i];
								point->clusterID = UNCLASSIFIED;

								cluster_input.push_back(*point);
								free(point);
							}
						}
					}
				}

				// constructor
				DBSCAN ds(MINIMUM_POINTS, EPSILON, cluster_input);

				// main loop
				ds.run();

				// result of DBSCAN algorithm
				printResults(ds.m_points, ds.getTotalPointSize(), argv[2]);
				cluster_input.clear();
			}
		}
		input.close();
	}

	return 0;
}