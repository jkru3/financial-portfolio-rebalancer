// portfolio_rebalancer.hpp
#pragma once
#include "models.hpp"
#include "strategies.hpp"
#include <unordered_map>
#include <memory>
#include <set>

class PortfolioRebalancer {
private:
    std::unordered_map<std::string, std::unordered_map<std::string, double>> stock_data_cache;
    std::unordered_map<std::string, std::set<std::string>> date_to_sectors_cache;
    std::unordered_map<std::string, std::string> ticker_to_sector_cache;
    std::unordered_map<std::string, double> speculated_roi_cache;
    std::unordered_map<std::string, std::tuple<double, double, double>> actual_roi_cache;

    std::string get_future_date(const std::string& current_date, int holding_window);
    void preprocess_stock_data(const std::string& stock_data_path);
    std::set<std::string> get_sectors_from_date(const std::string& date);
    double get_stock_price(const std::string& ticker, const std::string& date);
    double get_speculated_roi(const std::vector<double>& ticker_data,
                            Strategy& strategy,
                            const std::string& ticker,
                            const std::string& date,
                            int holding_window);
    std::optional<std::tuple<double, double, double>> get_actual_roi(
        const std::vector<double>& ticker_data,
        const std::string& ticker,
        const std::string& start_date,
        int holding_window);
    std::vector<std::pair<std::string, double>> get_ranked_stocks(
        Strategy& speculation_strategy,
        const std::string& portfolio_date,
        int holding_window);
    RebalanceSummary get_rebalance_summary(
        const std::vector<RebalanceAction>& actions,
        double remaining_cash);

public:
    PortfolioRebalancer() = default;
    
    std::tuple<std::vector<RebalanceAction>, RebalanceSummary, Portfolio> rebalance_portfolio(
        Strategy& speculation_strategy,
        int holding_window,
        int max_holdings,
        int max_sector_lead,
        double adjust_by);

    void clear_caches();
};