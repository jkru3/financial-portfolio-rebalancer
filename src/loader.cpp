// loader.cpp
#include "loader.hpp"
#include <fstream>
#include <sstream>

Portfolio Loader::load_portfolio(const std::string& portfolio_path) {
    std::ifstream f(portfolio_path);
    if (!f.is_open()) {
        throw std::runtime_error("Could not open portfolio file");
    }
    
    json data = json::parse(f);
    return Portfolio{
        data["id"],
        data["date"],
        data["cash"],
        data["holdings"]
    };
}

std::vector<StockData> Loader::load_stock_data(const std::string& csv_path) {
    std::vector<StockData> result;
    std::ifstream file(csv_path);
    if (!file.is_open()) {
        throw std::runtime_error("Could not open stock data file");
    }
    
    std::string line;
    std::getline(file, line); // Skip header
    
    while (std::getline(file, line)) {
        std::stringstream ss(line);
        StockData data;
        
        std::string token;
        std::vector<std::string> tokens;
        while (std::getline(ss, token, ',')) {
            tokens.push_back(token);
        }
        
        if (tokens.size() < 8) continue;
        
        data.ticker = tokens[0];
        data.sector = tokens[1];
        data.date = tokens[2];
        data.close = std::stod(tokens[3]);
        data.open = std::stod(tokens[4]);
        data.low = std::stod(tokens[5]);
        data.high = std::stod(tokens[6]);
        data.volume = std::stoi(tokens[7]);
        
        result.push_back(data);
    }
    
    return result;
}