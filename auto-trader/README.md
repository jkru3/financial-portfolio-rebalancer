# Stock Analyzer
This application takes in a portfolio (formatted in data/portfolio.json) which contains a date, available cash, and stock holdings. We then look ahead for a period of time and speculate on every stock in the stock data we have available (which can be hundreds or thousands of stocks).

We then rank these speculations against the stocks currently in our portfolio and then move money from the speculated lowest performers to the speculated highest performers

There are a few constant variables (hyper parameters) that can be modified in the usage which can be found in main.cpp:
- lookback_period
- holding_window
- max_holdings
- max_sector_lead

Currently the portfolio uses a very simple moving average strategy to make predictions in strategies.cpp but five things could be done to scale the effectiveness of this project in the future:
1. Integration with a dbms for more stocks and stock data
2. Inclusion of more involved data on stocks, like daily twitter trends and financial report metrics
3. More advanced strategies involving this greater depth and breadth of data
4. Greater efficiency in reading and performing calculations on frequently used data for 'tuning' the hyper-parameters
5. Using a deep learning model itself as a strategy for making speculations


## Prerequisites
- CMake 3.15 or higher
- vcpkg package manager
- C++20 compatible compiler

## vcpkg 

### Install vcpkg if you haven't already:
```bash
git clone https://github.com/Microsoft/vcpkg.git
./vcpkg/bootstrap-vcpkg.sh
```

### Set vcpkg local environment variable
```bash
echo 'export VCPKG_ROOT="$HOME/vcpkg"' >> ~/.bashrc
```

### Make sure you're in your project root
```bash
mkdir build
cd build
cmake ..
cmake --build .
```

### Debug
```bash
cmake -DCMAKE_BUILD_TYPE=Debug
cmake --build .
lldb [usage]
```

## Usage
```bash
./stock_analyzer
```

# TODO:
- We need future stock prediction
- portfolios should write to new portfolio file and open new one
- for loop on portfolio
- make code more efficient
- data needs to be updated in the build