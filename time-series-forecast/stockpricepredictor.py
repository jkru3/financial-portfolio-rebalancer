import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import matplotlib.pyplot as plt
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score

class StockPricePredictor:
    def __init__(self, csv_file, prediction_days=30):
        """
        Initialize the stock price predictor with a CSV file
        
        Parameters:
        -----------
        csv_file : str
            Path to the CSV file with columns: ticker, sector, date, close, open, low, high, volume
        prediction_days : int
            Number of days to use for creating features
        """
        self.prediction_days = prediction_days
        self.data = None
        self.model = None
        self.scaler = StandardScaler()
        self.tickers = None
        self.sectors = None
        
        # Load the CSV file
        self.load_data(csv_file)
        
    def load_data(self, csv_file):
        """Load and prepare the data from the CSV file"""
        # Read the CSV file
        df = pd.read_csv(csv_file)
        
        # Convert date column to datetime
        df['date'] = pd.to_datetime(df['date'])
        
        # Sort by ticker and date
        df = df.sort_values(['ticker', 'date'])
        
        # Store unique tickers and sectors
        self.tickers = df['ticker'].unique()
        self.sectors = df['sector'].unique()
        
        self.data = df
        print(f"Loaded data with {len(df)} rows and {len(self.tickers)} unique tickers")
        return df
    
    def create_features(self, ticker_filter=None):
        """
        Create features for the prediction model
        
        Parameters:
        -----------
        ticker_filter : str or list, optional
            Filter data to specific ticker(s)
            
        Returns:
        --------
        X : pd.DataFrame
            Features for training
        y : pd.Series
            Target values (future closing prices)
        """
        if ticker_filter:
            if isinstance(ticker_filter, str):
                ticker_filter = [ticker_filter]
            df = self.data[self.data['ticker'].isin(ticker_filter)].copy()
        else:
            df = self.data.copy()
        
        # Create a dictionary to store processed dataframes
        processed_dfs = []
        
        # Process each ticker separately
        for ticker in df['ticker'].unique():
            ticker_data = df[df['ticker'] == ticker].copy()
            
            if len(ticker_data) <= self.prediction_days:
                print(f"Not enough data for ticker {ticker}. Skipping.")
                continue
                
            # Create features from historical prices
            for i in range(1, self.prediction_days + 1):
                ticker_data[f'close_lag_{i}'] = ticker_data['close'].shift(i)
                ticker_data[f'open_lag_{i}'] = ticker_data['open'].shift(i)
                ticker_data[f'low_lag_{i}'] = ticker_data['low'].shift(i)
                ticker_data[f'high_lag_{i}'] = ticker_data['high'].shift(i)
                ticker_data[f'volume_lag_{i}'] = ticker_data['volume'].shift(i)
            
            # Create technical indicators
            # Moving averages
            ticker_data['ma_5'] = ticker_data['close'].rolling(window=5).mean()
            ticker_data['ma_10'] = ticker_data['close'].rolling(window=10).mean()
            ticker_data['ma_20'] = ticker_data['close'].rolling(window=20).mean()
            
            # Volatility
            ticker_data['volatility_5'] = ticker_data['close'].rolling(window=5).std()
            
            # Daily returns
            ticker_data['daily_return'] = ticker_data['close'].pct_change()
            
            # Target: Next day's closing price
            ticker_data['target'] = ticker_data['close'].shift(-1)
            
            processed_dfs.append(ticker_data)
        
        # Combine processed dataframes
        processed_df = pd.concat(processed_dfs)
        
        # Drop rows with NaN values
        processed_df = processed_df.dropna()
        
        # One-hot encode categorical variables
        processed_df = pd.get_dummies(processed_df, columns=['ticker', 'sector'])
        
        # Prepare features (X) and target (y)
        feature_columns = [col for col in processed_df.columns if col not in ['date', 'target', 'close', 'open', 'high', 'low', 'volume']]
        X = processed_df[feature_columns]
        y = processed_df['target']
        
        return X, y, processed_df
    
    def train_model(self, ticker_filter=None, test_size=0.2, random_state=42):
        """
        Train the prediction model
        
        Parameters:
        -----------
        ticker_filter : str or list, optional
            Filter data to specific ticker(s)
        test_size : float
            Proportion of the dataset to include in the test split
        random_state : int
            Random seed for reproducibility
            
        Returns:
        --------
        dict
            Dictionary with model performance metrics
        """
        # Create features
        X, y, _ = self.create_features(ticker_filter)
        
        # Split the data
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=test_size, random_state=random_state)
        
        # Scale the features
        X_train_scaled = self.scaler.fit_transform(X_train)
        X_test_scaled = self.scaler.transform(X_test)
        
        # Train a Random Forest model
        model = RandomForestRegressor(n_estimators=100, random_state=random_state)
        model.fit(X_train_scaled, y_train)
        
        # Make predictions
        y_pred = model.predict(X_test_scaled)
        
        # Calculate metrics
        mae = mean_absolute_error(y_test, y_pred)
        mse = mean_squared_error(y_test, y_pred)
        rmse = np.sqrt(mse)
        r2 = r2_score(y_test, y_pred)
        
        # Store the model
        self.model = model
        
        # Return metrics
        metrics = {
            'mae': mae,
            'mse': mse,
            'rmse': rmse,
            'r2': r2
        }
        
        print(f"Model trained with metrics: MAE={mae:.2f}, RMSE={rmse:.2f}, R²={r2:.2f}")
        return metrics
    
    def predict_future_price(self, ticker, target_date):
        """
        Predict the closing price for a specific ticker on a target date
        
        Parameters:
        -----------
        ticker : str
            The stock ticker to make predictions for
        target_date : str or datetime
            The date to predict the closing price for
            
        Returns:
        --------
        float
            Predicted closing price
        """
        if self.model is None:
            raise ValueError("Model not trained. Call train_model() first.")
        
        if ticker not in self.tickers:
            raise ValueError(f"Ticker {ticker} not found in the training data.")
            
        # Convert target_date to datetime if it's a string
        if isinstance(target_date, str):
            target_date = pd.to_datetime(target_date)
            
        # Get the most recent data for the ticker
        ticker_data = self.data[self.data['ticker'] == ticker].copy()
        
        # Check if we have data until the target date
        if ticker_data['date'].max() >= target_date:
            # We already have the date in our dataset
            return ticker_data.loc[ticker_data['date'] == target_date, 'close'].values[0]
        
        # Sort by date (descending) and take the most recent data
        ticker_data = ticker_data.sort_values('date', ascending=False).head(self.prediction_days + 1)
        
        if len(ticker_data) < self.prediction_days:
            raise ValueError(f"Not enough historical data for ticker {ticker}")
            
        # Create features similar to the training process
        current_features = {}
        
        # Historical prices
        for i in range(1, self.prediction_days + 1):
            current_features[f'close_lag_{i}'] = ticker_data['close'].iloc[i-1]
            current_features[f'open_lag_{i}'] = ticker_data['open'].iloc[i-1]
            current_features[f'low_lag_{i}'] = ticker_data['low'].iloc[i-1]
            current_features[f'high_lag_{i}'] = ticker_data['high'].iloc[i-1]
            current_features[f'volume_lag_{i}'] = ticker_data['volume'].iloc[i-1]
        
        # Moving averages
        current_features['ma_5'] = ticker_data['close'].iloc[:5].mean()
        current_features['ma_10'] = ticker_data['close'].iloc[:10].mean()
        current_features['ma_20'] = ticker_data['close'].iloc[:20].mean() if len(ticker_data) >= 20 else ticker_data['close'].mean()
        
        # Volatility
        current_features['volatility_5'] = ticker_data['close'].iloc[:5].std()
        
        # Daily return
        current_features['daily_return'] = (ticker_data['close'].iloc[0] - ticker_data['close'].iloc[1]) / ticker_data['close'].iloc[1]
        
        # One-hot encode ticker and sector
        sector = ticker_data['sector'].iloc[0]
        
        # Create one-hot encoded columns for ticker and sector
        for t in self.tickers:
            current_features[f'ticker_{t}'] = 1 if t == ticker else 0
            
        for s in self.sectors:
            current_features[f'sector_{s}'] = 1 if s == sector else 0
            
        # Convert to DataFrame
        features_df = pd.DataFrame([current_features])
        
        # Make sure we have all the columns from training
        X, _, _ = self.create_features()
        for col in X.columns:
            if col not in features_df.columns:
                features_df[col] = 0
                
        # Reorder columns to match training data
        features_df = features_df[X.columns]
        
        # Scale the features
        features_scaled = self.scaler.transform(features_df)
        
        # Make prediction
        predicted_price = self.model.predict(features_scaled)[0]
        
        print(f"Predicted closing price for {ticker} on {target_date.strftime('%Y-%m-%d')}: ${predicted_price:.2f}")
        return predicted_price
    
    def visualize_predictions(self, ticker, days_to_predict=30):
        """
        Visualize historical prices and predictions for a specific ticker
        
        Parameters:
        -----------
        ticker : str
            The stock ticker to visualize
        days_to_predict : int
            Number of days to predict into the future
        """
        if self.model is None:
            raise ValueError("Model not trained. Call train_model() first.")
            
        # Get historical data for the ticker
        ticker_data = self.data[self.data['ticker'] == ticker].copy()
        ticker_data = ticker_data.sort_values('date')
        
        # Historical dates and prices
        historical_dates = ticker_data['date']
        historical_prices = ticker_data['close']
        
        # Generate future dates
        last_date = ticker_data['date'].max()
        future_dates = [last_date + timedelta(days=i) for i in range(1, days_to_predict + 1)]
        
        # Predict future prices
        future_prices = []
        for date in future_dates:
            try:
                price = self.predict_future_price(ticker, date)
                future_prices.append(price)
            except Exception as e:
                print(f"Error predicting price for {date}: {str(e)}")
                break
                
        # Plot
        plt.figure(figsize=(12, 6))
        plt.plot(historical_dates, historical_prices, label='Historical Prices')
        
        if future_prices:
            plt.plot(future_dates[:len(future_prices)], future_prices, 'r--', label='Predicted Prices')
            
        plt.title(f'{ticker} Stock Price Prediction')
        plt.xlabel('Date')
        plt.ylabel('Closing Price ($)')
        plt.legend()
        plt.grid(True)
        plt.xticks(rotation=45)
        plt.tight_layout()
        
        # Save the figure
        plt.savefig(f'{ticker}_prediction.png')
        plt.close()
        
        print(f"Prediction visualization saved as {ticker}_prediction.png")

# Example usage
if __name__ == "__main__":
    # Initialize the predictor
    predictor = StockPricePredictor('stock_data.csv')
    
    # Train the model
    predictor.train_model()
    
    # Make predictions for a specific ticker and date
    ticker = 'AAPL'  # Replace with a ticker from your dataset
    target_date = '2023-12-31'  # Replace with a future date
    
    try:
        predicted_price = predictor.predict_future_price(ticker, target_date)
        print(f"Predicted closing price for {ticker} on {target_date}: ${predicted_price:.2f}")
        
        # Visualize predictions
        predictor.visualize_predictions(ticker)
    except ValueError as e:
        print(f"Error: {str(e)}")