// models.hpp
#pragma once
#include <string>
#include <vector>
#include <optional>
#include <map>
#include <nlohmann/json.hpp>
using json = nlohmann::json;

// Add these before the Portfolio struct definition
namespace nlohmann {
    template <typename... Args>
    struct adl_serializer<std::variant<Args...>> {
        static std::variant<Args...> from_json(const json& j) {
            std::variant<Args...> var;
            if (j.is_string()) {
                var = j.get<std::string>();
            } else if (j.is_number_integer()) {
                var = j.get<int>();
            }
            return var;
        }
        
        static void to_json(json& j, const std::variant<Args...>& var) {
            std::visit([&j](auto&& arg) { j = arg; }, var);
        }
    };
}

struct Portfolio {
    std::string id;
    std::string date;
    double cash;
    std::vector<std::map<std::string, std::variant<std::string, int>>> holdings;

    json to_dict() const {
        json j;
        j["id"] = id;
        j["date"] = date;
        j["cash"] = cash;
        
        json holdings_array = json::array();
        for (const auto& holding : holdings) {
            json holding_obj;
            for (const auto& [key, value] : holding) {
                std::visit([&holding_obj, &key](const auto& v) {
                    holding_obj[key] = v;
                }, value);
            }
            holdings_array.push_back(holding_obj);
        }
        j["holdings"] = holdings_array;
        
        return j;
    }
};

struct RebalanceAction {
    std::string action_type;
    std::string ticker;
    int traded_shares;
    double speculated_roi;
    double speculated_net_capital;
    int outstanding_shares;
    double new_holding_value;
    std::optional<double> actual_roi;
    std::optional<double> actual_net_capital;
};

struct RebalanceSummary {
    double total_portfolio_value;
    double remaining_cash;
    double average_speculated_roi;
    double total_speculated_net_capital;
    std::optional<double> average_actual_roi;
    std::optional<double> total_actual_net_capital;
};