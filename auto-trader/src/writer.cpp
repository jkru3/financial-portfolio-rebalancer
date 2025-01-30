// writer.cpp
#include "writer.hpp"
#include <fstream>

void Writer::make_portfolio(const Portfolio& portfolio, const std::string& output_path) {
    std::ofstream file(output_path);
    if (!file.is_open()) {
        throw std::runtime_error("Could not open output file for writing");
    }
    
    json j = portfolio.to_dict();
    file << j.dump(4);
}