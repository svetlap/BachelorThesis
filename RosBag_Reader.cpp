#include <iostream>
#include <fstream>
#include <string>
#include <vector>

#define COLUMNS 1224
#define ROWS    720
#define OFFSET  (sizeof("data: "))

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

imgPixel construct_pixel(char X, char Y, char flag) {
	imgPixel temp_pixel = { X, Y, flag };
	return temp_pixel;
}

void RosBag_reader(const char* input_param, const char* output_param)
{
	std::cout << input_param <<" "<< output_param<<std::endl;
	std::ifstream input(input_param);
	std::ofstream output;
	size_t counter = 0;
	for (std::string line; getline(input, line); )
	{
		if (line.find("data") != std::string::npos)
		{
			std::string frame_name(output_param);
			frame_name.append(std::to_string(counter));
			frame_name.append(".txt");

			output.open(frame_name.c_str());// , std::ios_base::app);

			size_t i = 0;
			for (; i < line.length(); i++)
			{
				if (isdigit(line[i]))
				{
					if (line[i] != '0') // Change to filter out other flags, example == '1'
					{
						uint32_t new_X = calculate_X((i - OFFSET) / 3);
						uint32_t new_Y = calculate_Y((i - OFFSET) / 3);
						std::cout << new_X << " "
							<< new_Y << " " << line[i] << std::endl;

						output << new_X << " " << new_Y << " " << line[i] << std::endl;

						//cluster_input.push_back(construct_pixel(calculate_X((i - OFFSET) / 3), calculate_Y((i - OFFSET) / 3), line[i]));
					}
				}
			}
			//output << "-------------------------------------------------------------------------------------------" << std::endl;
			output.close();
			++counter;
			//std::cout << "-------------------------------------------------------------------------------------------" << std::endl;
		}
	}
	input.close();
	//output.close();
}

int main(int argc, char *argv[])
{
	//char step_buffer[5] = { 0 };
	char X = 0;
	char Y = 0;
	char flag = 0;
	std::vector<imgPixel> cluster_input;
	//std::vector < std::vector<imgPixel>> imgFrames;

	if (argc > 1)
	{
		RosBag_reader(argv[1], argv[2]);
		/*
		for (size_t i = 0; i < cluster_input.size(); i++) {
			std::cout << "[" << cluster_input[i].X << "]["
				<< cluster_input[i].Y << "][" << cluster_input[i].flag << "]" << std::endl;
		}*/
	}
	else
	{
		std::cout << argc << std::endl;
	}

	return 0;
}