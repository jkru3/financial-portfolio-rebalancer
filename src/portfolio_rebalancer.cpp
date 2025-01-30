#include "portfolio_rebalancer.hpp"
#include <fstream>
#include <sstream>
#include <algorithm>
#include <cmath>
#include <numeric>
#include <iostream>

std::string PortfolioRebalancer::get_future_date(const std::string& current_date, int holding_window) {
    std::vector<std::string> all_dates;
    for (const auto& [date_key, _] : date_to_sectors_cache) {
        all_dates.push_back(date_key);
    }
    
    std::sort(all_dates.begin(), all_dates.end());
    auto current_it = std::find(all_dates.begin(), all_dates.end(), current_date);
    
    if (current_it == all_dates.end()) {
        throw std::runtime_error("Current date not found in data");
    }
    
    if (std::distance(current_it, all_dates.end()) <= holding_window) {
        throw std::runtime_error("Not enough future data available");
    }
    
    return *(current_it + holding_window);
}

void PortfolioRebalancer::preprocess_stock_data(const std::string& stock_data_path) {
    std::ifstream file(stock_data_path);
    if (!file.is_open()) {
        throw std::runtime_error("Could not open stock data file: " + stock_data_path);
    }

    std::string line;
    std::getline(file, line); // Skip header

    while (std::getline(file, line)) {
        std::stringstream ss(line);
        std::string ticker, date, sector;
        double close, open, low, high;
        int volume;
        
        // Parse CSV line
        std::string token;
        std::vector<std::string> tokens;
        while (std::getline(ss, token, ',')) {
            tokens.push_back(token);
        }
        
        if (tokens.size() < 8) continue; // Skip invalid lines
        
        ticker = tokens[0];
        sector = tokens[1];
        date = tokens[2];
        close = std::stod(tokens[3]);
        open = std::stod(tokens[4]);
        low = std::stod(tokens[5]);
        high = std::stod(tokens[6]);
        volume = std::stoi(tokens[7]);

        // Cache the data
        stock_data_cache[date][ticker] = close;
        ticker_to_sector_cache[ticker] = sector;
        date_to_sectors_cache[date].insert(sector);
    }
}

std::set<std::string> PortfolioRebalancer::get_sectors_from_date(const std::string& date) {
    auto it = date_to_sectors_cache.find(date);
    if (it == date_to_sectors_cache.end()) {
        throw std::runtime_error("No sector data found for date: " + date);
    }
    return it->second;
}

double PortfolioRebalancer::get_stock_price(const std::string& ticker, const std::string& date) {
    auto date_it = stock_data_cache.find(date);
    if (date_it == stock_data_cache.end()) {
        throw std::runtime_error("No data found for date: " + date);
    }
    
    auto ticker_it = date_it->second.find(ticker);
    if (ticker_it == date_it->second.end()) {
        throw std::runtime_error("No price data found for ticker: " + ticker + " on date: " + date);
    }
    
    return ticker_it->second;
}

double PortfolioRebalancer::get_speculated_roi(
    const std::vector<double>& ticker_data,
    Strategy& strategy,
    const std::string& ticker,
    const std::string& date,
    int holding_window) {
    
    std::string cache_key = ticker + "_" + date + "_" + 
                           std::to_string(holding_window) + "_" + 
                           typeid(strategy).name();
    
    auto it = speculated_roi_cache.find(cache_key);
    if (it != speculated_roi_cache.end()) {
        return it->second;
    }
    
    try {
        double roi = strategy.speculate(ticker_data, date, holding_window);
        speculated_roi_cache[cache_key] = roi;
        return roi;
    } catch (const std::exception& e) {
        std::cerr << "Error processing " << ticker << ": " << e.what() << std::endl;
        return 0.0;
    }
}

std::optional<std::tuple<double, double, double>> PortfolioRebalancer::get_actual_roi(
    const std::vector<double>& ticker_data,
    const std::string& ticker,
    const std::string& start_date,
    int holding_window) {
    
    std::string cache_key = ticker + "_" + start_date + "_" + std::to_string(holding_window);
    
    auto it = actual_roi_cache.find(cache_key);
    if (it != actual_roi_cache.end()) {
        return it->second;
    }
    
    if (ticker_data.empty()) {
        return std::nullopt;
    }
    
    try {
        double start_price = get_stock_price(ticker, start_date);
        auto future_date = get_future_date(start_date, holding_window);
        double end_price = get_stock_price(ticker, future_date);
        double actual_roi = (end_price - start_price) / start_price;
        
        auto result = std::make_tuple(start_price, end_price, actual_roi);
        actual_roi_cache[cache_key] = result;
        return result;
    } catch (const std::exception&) {
        return std::nullopt;
    }
}

std::vector<std::pair<std::string, double>> PortfolioRebalancer::get_ranked_stocks(
    Strategy& speculation_strategy,
    const std::string& portfolio_date,
    int holding_window) {
    
    std::vector<std::pair<std::string, double>> rankings;
    std::set<std::string> seen_tickers;
    
    for (const auto& [ticker, price] : stock_data_cache[portfolio_date]) {
        if (seen_tickers.find(ticker) != seen_tickers.end()) {
            continue;
        }
        
        seen_tickers.insert(ticker);
        
        // Gather historical data for this ticker
        std::vector<double> ticker_data;
        for (const auto& [date, prices] : stock_data_cache) {
            if (date <= portfolio_date) {
                auto it = prices.find(ticker);
                if (it != prices.end()) {
                    ticker_data.push_back(it->second);
                }
            }
        }
        
        double speculated_roi = get_speculated_roi(
            ticker_data,
            speculation_strategy,
            ticker,
            portfolio_date,
            holding_window
        );
        
        if (speculated_roi != 0.0) {
            rankings.emplace_back(ticker, speculated_roi);
        }
    }
    
    std::sort(rankings.begin(), rankings.end(),
              [](const auto& a, const auto& b) { return a.second > b.second; });
    
    return rankings;
}

RebalanceSummary PortfolioRebalancer::get_rebalance_summary(
    const std::vector<RebalanceAction>& actions,
    double remaining_cash) {
    
    if (actions.empty()) {
        return RebalanceSummary{
            remaining_cash,
            remaining_cash,
            0.0,
            0.0,
            std::nullopt,
            std::nullopt
        };
    }
    
    double total_portfolio_value = remaining_cash;
    std::vector<double> speculated_rois;
    double total_speculated_net_capital = 0.0;
    std::vector<double> actual_rois;
    double total_actual_net_capital = 0.0;
    
    for (const auto& action : actions) {
        total_portfolio_value += action.new_holding_value;
        speculated_rois.push_back(action.speculated_roi);
        total_speculated_net_capital += action.speculated_net_capital;
        
        if (action.actual_roi) {
            actual_rois.push_back(*action.actual_roi);
            total_actual_net_capital += *action.actual_net_capital;
        }
    }
    
    double avg_speculated_roi = std::accumulate(speculated_rois.begin(), 
                                              speculated_rois.end(), 0.0) / 
                               speculated_rois.size();
    
    std::optional<double> avg_actual_roi;
    if (!actual_rois.empty()) {
        avg_actual_roi = std::accumulate(actual_rois.begin(), 
                                       actual_rois.end(), 0.0) / 
                        actual_rois.size();
    }
    
    return RebalanceSummary{
        total_portfolio_value,
        remaining_cash,
        avg_speculated_roi,
        total_speculated_net_capital,
        avg_actual_roi,
        total_actual_net_capital
    };
}

std::tuple<std::vector<RebalanceAction>, RebalanceSummary, Portfolio>
PortfolioRebalancer::rebalance_portfolio(
    Strategy& speculation_strategy,
    int holding_window,
    int max_holdings,
    int max_sector_lead,
    double adjust_by) {
    
    // Load and preprocess data
    preprocess_stock_data("./data/stock_data.csv");
    
    // Load portfolio from JSON file
    std::ifstream f("./data/portfolio.json");
    if (!f.is_open()) {
        throw std::runtime_error("Could not open portfolio file");
    }
    json portfolio_json = json::parse(f);
    Portfolio portfolio{
        portfolio_json["id"],
        portfolio_json["date"],
        portfolio_json["cash"],
        portfolio_json["holdings"]
    };
    
    auto sectors = get_sectors_from_date(portfolio.date);
    
    // Calculate current holdings and valuations
    std::unordered_map<std::string, int> old_holdings;
    std::unordered_map<std::string, double> old_portfolio_valuations;
    double total_value = portfolio.cash;
    
    for (const auto& holding : portfolio.holdings) {
        std::string ticker = std::get<std::string>(holding.at("ticker"));
        int quantity = std::get<int>(holding.at("quantity"));
        old_holdings[ticker] = quantity;
        
        double price = get_stock_price(ticker, portfolio.date);
        double value = price * quantity;
        total_value += value;
        old_portfolio_valuations[ticker] = value;
    }

    // Get current holdings ranked by speculated ROI
    std::vector<std::pair<std::string, double>> old_ranked_stocks;
    for (const auto& [ticker, quantity] : old_holdings) {
        std::vector<double> ticker_data;
        for (const auto& [date, prices] : stock_data_cache) {
            if (date <= portfolio.date) {
                auto it = prices.find(ticker);
                if (it != prices.end()) {
                    ticker_data.push_back(it->second);
                }
            }
        }
        
        double speculated_roi = get_speculated_roi(
            ticker_data,
            speculation_strategy,
            ticker,
            portfolio.date,
            holding_window
        );
        old_ranked_stocks.emplace_back(ticker, speculated_roi);
    }
    std::sort(old_ranked_stocks.begin(), old_ranked_stocks.end(),
              [](const auto& a, const auto& b) { return a.second > b.second; });

    // Get all available stocks ranked by ROI
    auto unfiltered_ranked_stocks = get_ranked_stocks(
        speculation_strategy,
        portfolio.date,
        holding_window
    );

    // Filter stocks ensuring sector balance
    std::vector<std::pair<std::string, double>> ranked_stocks;
    std::unordered_map<std::string, int> sector_counts;
    for (const auto& sector : sectors) {
        sector_counts[sector] = 0;
    }

    while (ranked_stocks.size() < max_holdings && !unfiltered_ranked_stocks.empty()) {
        // First try to keep high-performing current holdings
        if (!old_ranked_stocks.empty() && !unfiltered_ranked_stocks.empty() &&
            old_ranked_stocks.front().first == unfiltered_ranked_stocks.front().first) {
            ranked_stocks.push_back(old_ranked_stocks.front());
            old_ranked_stocks.erase(old_ranked_stocks.begin());
            unfiltered_ranked_stocks.erase(unfiltered_ranked_stocks.begin());
        } else {
            auto& [ticker, roi] = unfiltered_ranked_stocks.front();
            std::string sector = ticker_to_sector_cache[ticker];
            int min_sector_count = std::min_element(
                sector_counts.begin(), sector_counts.end(),
                [](const auto& a, const auto& b) { return a.second < b.second; }
            )->second;

            if (sector_counts[sector] < min_sector_count + max_sector_lead) {
                sector_counts[sector]++;
                ranked_stocks.push_back(unfiltered_ranked_stocks.front());
            }
            unfiltered_ranked_stocks.erase(unfiltered_ranked_stocks.begin());
        }
    }

    // Add remaining old stocks at the end
    ranked_stocks.insert(ranked_stocks.end(), 
                        old_ranked_stocks.begin(), 
                        old_ranked_stocks.end());

    // Calculate target valuations
    std::unordered_map<std::string, double> new_portfolio_valuations;
    int n = std::min(max_holdings, static_cast<int>(ranked_stocks.size()));
    for (int i = 0; i < ranked_stocks.size(); ++i) {
        const auto& [ticker, _] = ranked_stocks[i];
        if (i < n) {
            new_portfolio_valuations[ticker] = (2.0 * (n - i) * total_value) / (n * n);
        } else {
            new_portfolio_valuations[ticker] = 0.0;
        }
    }

    // Blend valuations
    std::unordered_map<std::string, double> blended_portfolio_valuations;
    std::set<std::string> all_tickers;
    for (const auto& [ticker, _] : old_portfolio_valuations) all_tickers.insert(ticker);
    for (const auto& [ticker, _] : new_portfolio_valuations) all_tickers.insert(ticker);

    for (const auto& ticker : all_tickers) {
        double old_val = old_portfolio_valuations.count(ticker) ? 
                        old_portfolio_valuations[ticker] : 0.0;
        double new_val = new_portfolio_valuations.count(ticker) ? 
                        new_portfolio_valuations[ticker] : 0.0;
        blended_portfolio_valuations[ticker] = old_val * (1 - adjust_by) + new_val * adjust_by;
    }

    // SELLS to free up cash
    double available_cash = portfolio.cash;
    std::vector<RebalanceAction> actions;

    for (const auto& [ticker, speculated_roi] : ranked_stocks) {
        double current_val = old_portfolio_valuations.count(ticker) ? 
                            old_portfolio_valuations[ticker] : 0.0;
        double target_val = blended_portfolio_valuations.count(ticker) ? 
                        blended_portfolio_valuations[ticker] : 0.0;
        
        std::cout << "Current ticker: " << ticker << std::endl;
        if (current_val > target_val) {
            double current_price = get_stock_price(ticker, portfolio.date);
            int current_quantity = old_holdings[ticker];
            int target_quantity = static_cast<int>(target_val / current_price);
            int shares_to_sell = current_quantity - target_quantity;
            double new_holding_value = target_quantity * current_price;
            
            if (shares_to_sell > 0) {
                std::cout << "selling shares ticker: " << ticker << std::endl;
                RebalanceAction action{
                    "SELL",
                    ticker,
                    shares_to_sell,
                    speculated_roi,
                    new_holding_value * speculated_roi,
                    target_quantity,
                    new_holding_value,
                    std::nullopt,
                    std::nullopt
                };
                actions.push_back(action);
                available_cash += current_price * shares_to_sell;
            } else if (target_quantity > 0) {
                std::cout << "target quantity ticker: " << ticker << std::endl;
                RebalanceAction hold_action{
                    "HOLD",
                    ticker,
                    0,
                    speculated_roi,
                    new_holding_value * speculated_roi,
                    target_quantity,
                    new_holding_value,
                    std::nullopt,
                    std::nullopt
                };
                actions.push_back(hold_action);
            }
        }
    }

    // BUY initial stocks starting with highest projections first
    struct BuyCandidate {
        std::string ticker;
        double speculated_roi;
        int shares_to_buy;
        double share_price;
    };

    std::vector<BuyCandidate> buy_candidates;

    for (const auto& [ticker, speculated_roi] : ranked_stocks) {
        double current_val = old_portfolio_valuations.count(ticker) ? 
                            old_portfolio_valuations[ticker] : 0.0;
        double target_val = blended_portfolio_valuations.count(ticker) ? 
                        blended_portfolio_valuations[ticker] : 0.0;
        
        if (target_val >= current_val) {
            double share_price = get_stock_price(ticker, portfolio.date);
            int current_quantity = old_holdings.count(ticker) ? old_holdings[ticker] : 0;
            int target_quantity = static_cast<int>(target_val / share_price);
            int shares_to_buy = target_quantity - current_quantity;

            BuyCandidate candidate{
                ticker,
                speculated_roi,
                shares_to_buy,
                share_price
            };

            available_cash -= share_price * shares_to_buy;
            buy_candidates.push_back(candidate);
        }
    }

    // Greedily buy up buy_candidates with remaining available cash
    for (auto& candidate : buy_candidates) {
        if (available_cash >= candidate.share_price) {
            candidate.shares_to_buy += 1;
            available_cash -= candidate.share_price;
        }
    }

    for (const auto& candidate : buy_candidates) {
        int outstanding_shares = (old_holdings.count(candidate.ticker) ? 
                                old_holdings[candidate.ticker] : 0) + 
                            candidate.shares_to_buy;
        double new_holding_value = outstanding_shares * candidate.share_price;
        
        if (candidate.shares_to_buy > 0) {
            RebalanceAction action{
                "BUY",
                candidate.ticker,
                candidate.shares_to_buy,
                candidate.speculated_roi,
                new_holding_value * candidate.speculated_roi,
                outstanding_shares,
                new_holding_value,
                std::nullopt,
                std::nullopt
            };
            actions.push_back(action);
        } else if (outstanding_shares > 0) {
            RebalanceAction hold_action{
                "HOLD",
                candidate.ticker,
                0,
                candidate.speculated_roi,
                new_holding_value * candidate.speculated_roi,
                outstanding_shares,
                new_holding_value,
                std::nullopt,
                std::nullopt
            };
            actions.push_back(hold_action);
        }
    }

    // Add future performance data if available
    for (auto& action : actions) {
        std::vector<double> ticker_data;
        for (const auto& [date, prices] : stock_data_cache) {
            auto it = prices.find(action.ticker);
            if (it != prices.end()) {
                ticker_data.push_back(it->second);
            }
        }
        
        auto future_perf = get_actual_roi(
            ticker_data,
            action.ticker,
            portfolio.date,
            holding_window
        );
        
        if (future_perf) {
            auto [start_price, end_price, actual_roi] = *future_perf;
            action.actual_roi = actual_roi;
            action.actual_net_capital = actual_roi * action.outstanding_shares * start_price;
        }
    }

    auto rebalance_summary = get_rebalance_summary(actions, available_cash);

    std::string future_date = get_future_date(portfolio.date, holding_window);

    // Convert JSON holdings to Portfolio's expected type
    std::vector<std::map<std::string, std::variant<std::string, int>>> new_holdings;
    for (const auto& action : actions) {
        std::map<std::string, std::variant<std::string, int>> holding;
        holding["ticker"] = action.ticker;
        holding["quantity"] = action.outstanding_shares;
        new_holdings.push_back(holding);
    }

    Portfolio new_portfolio{
        portfolio.id,
        future_date,
        available_cash,
        new_holdings
    };

    return {actions, rebalance_summary, new_portfolio};
}