// writer.hpp
#pragma once
#include "models.hpp"
#include <string>

class Writer {
public:
    static void make_portfolio(const Portfolio& portfolio, const std::string& output_path);
};