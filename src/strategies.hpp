// strategies.hpp
#pragma once
#include <vector>
#include <string>
#include <random>
#include <cmath>

class Strategy {
public:
    virtual ~Strategy() = default;
    virtual double speculate(const std::vector<double>& prices, 
                           const std::string& start_date, 
                           int period) = 0;
};

class RandomStrategy : public Strategy {
public:
    double speculate(const std::vector<double>& prices, 
                    const std::string& start_date, 
                    int period) override {
        std::random_device rd;
        std::mt19937 gen(rd());
        std::uniform_real_distribution<> dis(-0.1, 0.1);
        return dis(gen);
    }
};

class MovingAverageStrategy : public Strategy {
private:
    int short_window;
    int long_window;

    std::pair<std::vector<double>, std::vector<double>> calculate_moving_averages(
        const std::vector<double>& prices) {
        std::vector<double> short_ma(prices.size());
        std::vector<double> long_ma(prices.size());
        
        // Calculate moving averages
        for (size_t i = 0; i < prices.size(); ++i) {
            int short_start = std::max(0, static_cast<int>(i) - short_window + 1);
            int long_start = std::max(0, static_cast<int>(i) - long_window + 1);
            
            double short_sum = 0, long_sum = 0;
            int short_count = 0, long_count = 0;
            
            for (int j = short_start; j <= i; ++j) {
                short_sum += prices[j];
                ++short_count;
            }
            
            for (int j = long_start; j <= i; ++j) {
                long_sum += prices[j];
                ++long_count;
            }
            
            short_ma[i] = short_sum / short_count;
            long_ma[i] = long_sum / long_count;
        }
        
        return {short_ma, long_ma};
    }

    double calculate_momentum(const std::vector<double>& short_ma, 
                            const std::vector<double>& long_ma) {
        double short_last = short_ma.back();
        double long_last = long_ma.back();
        double diff_pct = (short_last - long_last) / long_last;
        return std::tanh(diff_pct * 10);  // Scale factor of 10 for better spread
    }

public:
    MovingAverageStrategy(int short_window = 20, int long_window = 50)
        : short_window(short_window), long_window(long_window) {}

    double speculate(const std::vector<double>& prices,
                    const std::string& start_date,
                    int holding_window) override {
        if (prices.size() < static_cast<size_t>(long_window)) {
            throw std::runtime_error("Not enough historical data for moving average speculation");
        }

        auto [short_ma, long_ma] = calculate_moving_averages(prices);
        double momentum = calculate_momentum(short_ma, long_ma);

        // Calculate historical volatility
        std::vector<double> returns(prices.size() - 1);
        for (size_t i = 1; i < prices.size(); ++i) {
            returns[i-1] = (prices[i] - prices[i-1]) / prices[i-1];
        }

        // Calculate standard deviation
        double mean = 0.0;
        for (double ret : returns) mean += ret;
        mean /= returns.size();

        double sq_sum = 0.0;
        for (double ret : returns) {
            sq_sum += (ret - mean) * (ret - mean);
        }
        double volatility = std::sqrt(sq_sum / (returns.size() - 1)) * std::sqrt(252);

        return momentum * volatility * (static_cast<double>(holding_window) / 252);
    }
};
