// loader.hpp
#pragma once
#include "models.hpp"
#include <string>
#include <vector>

struct StockData {
    std::string ticker;
    std::string sector;
    std::string date;
    double close;
    double open;
    double low;
    double high;
    int volume;
};

class Loader {
public:
    static Portfolio load_portfolio(const std::string& portfolio_path);
    static std::vector<StockData> load_stock_data(const std::string& csv_path);
};