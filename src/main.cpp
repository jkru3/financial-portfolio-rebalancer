// main.cpp
#include "portfolio_rebalancer.hpp"
#include <iostream>
#include <iomanip>

int main() {
    // CUSTOMIZE THESE THESE
    const int lookback_period = 50; // this is the period of historical data (in trading days) we look backwards
    const int holding_window = 10; // this is the number of trading days ahead we are speculating on
    const int max_holdings = 50; // this is the maximum number of stocks we are allowed to buy in a rebalance
    const int max_sector_lead = 5; // the max allowed difference between the most and least represesnted sector in our portfolio
    const double adjust_by = 1.0; // as we get from 0 to 1, we perscribe more and more adjustment to our portfolio

    auto speculation_strategy = std::make_unique<MovingAverageStrategy>(
        std::min(lookback_period, 20),
        std::min(lookback_period, 50)
    );

    PortfolioRebalancer rebalancer;

    try {
        auto [actions, rebalance_summary, new_portfolio] = rebalancer.rebalance_portfolio(
            *speculation_strategy,
            holding_window,
            max_holdings,
            max_sector_lead,
            adjust_by
        );

        // Print results
        for (const auto& action : actions) {
            std::cout << action.action_type << ": " << action.traded_shares 
                     << " shares of " << action.ticker << "\n";
            std::cout << "New holding value: $" << std::fixed 
                     << std::setprecision(2) << action.new_holding_value << "\n";
            std::cout << "Outstanding stock: " << action.outstanding_shares << "\n";
            std::cout << "Speculated ROI: " << action.speculated_roi * 100 << "%\n";
            std::cout << "Speculated net capital: $" << action.speculated_net_capital << "\n";
            
            if (action.actual_roi) {
                std::cout << "Actual ROI: " << *action.actual_roi * 100 << "%\n";
                std::cout << "Actual net capital: $" << *action.actual_net_capital << "\n";
            }
            std::cout << "\n";
        }

        std::cout << "Total portfolio value: $" << rebalance_summary.total_portfolio_value << "\n";
        std::cout << "Remaining cash: $" << rebalance_summary.remaining_cash << "\n";
        std::cout << "Average speculated ROI: " << rebalance_summary.average_speculated_roi * 100 << "%\n";
        std::cout << "Total speculated net capital: $" << rebalance_summary.total_speculated_net_capital << "\n";
        
        if (rebalance_summary.average_actual_roi) {
            std::cout << "Average actual ROI: " << *rebalance_summary.average_actual_roi * 100 << "%\n";
            std::cout << "Total actual net capital: $" << *rebalance_summary.total_actual_net_capital << "\n";
        }

    } catch (const std::exception& e) {
        std::cerr << "\nError: " << e.what() << std::endl;
        return 1;
    }

    return 0;
}