# MONET - Money Expense Tracker System

A comprehensive Flutter mobile application for personal finance management, built with Dart and integrated with a Laravel API backend.

## Overview

MONET (Money Expense Tracker) is a feature-rich financial management application that helps users track their income, expenses, transfers, and budgets. The app provides a clean, intuitive interface for managing multiple accounts, categorizing transactions, and monitoring financial goals.

## Features

### 🏦 Account Management
- **Multiple Account Support**: Create and manage multiple financial accounts (savings, checking, credit cards, etc.)
- **Account Types**: Support for different account types with customizable currency settings
- **Initial Balance Setup**: Set starting balances for each account
- **Account Overview**: View account balances and transaction history

### 💰 Transaction Management
- **Income Tracking**: Record income transactions with category classification
- **Expense Tracking**: Track expenses with detailed categorization
- **Transfer Management**: Handle money transfers between accounts with real-time exchange rates
- **Transaction History**: Comprehensive transaction listing with filtering options
- **Search & Filter**: Filter transactions by type (income, expense, transfer), amount, and date
- **Sorting Options**: Sort by highest/lowest amounts and newest/oldest dates

### 📊 Budget Management
- **Budget Creation**: Create budgets for specific categories or overall spending
- **Period-based Budgets**: Support for daily, weekly, monthly, and custom period budgets
- **Budget Tracking**: Monitor spending against budget limits with progress indicators
- **Notification System**: Set up alerts when approaching budget thresholds
- **Visual Progress**: Color-coded progress bars showing budget utilization

### 📈 Dashboard & Analytics
- **Home Dashboard**: Overview of financial status with charts and statistics
- **Transaction Charts**: Visual representation of spending patterns using FL Chart
- **Balance Overview**: Real-time account balance summaries
- **Period Filtering**: View data by today, week, or month
- **Category Breakdown**: Analyze spending by categories

### 👤 User Profile & Settings
- **User Profile Management**: Update personal information and settings
- **Authentication**: Secure login with email verification and PIN setup
- **Password Management**: Change password functionality
- **Account Settings**: Customize app preferences

### 🔒 Security Features
- **Email Verification**: Secure account verification process
- **PIN Protection**: Additional security layer with PIN setup
- **Token-based Authentication**: Secure API communication with Bearer tokens
- **Data Encryption**: Secure local data storage using Hive

### 📱 User Experience
- **Material Design**: Clean, modern UI following Material Design principles
- **Responsive Layout**: Optimized for different screen sizes
- **Bottom Navigation**: Easy navigation between main sections
- **Form Validation**: Comprehensive input validation for all forms
- **Loading States**: Smooth loading indicators for better user experience
- **Error Handling**: User-friendly error messages and feedback

## Technical Architecture

### Frontend (Flutter/Dart)
- **Framework**: Flutter 3.x with Dart
- **State Management**: StatefulWidget with setState
- **Local Storage**: Hive for offline data persistence
- **HTTP Client**: Dio for API communication
- **Charts**: FL Chart for data visualization
- **Navigation**: Named routes with custom navigation handling

### Backend Integration
- **API**: Laravel-based REST API
- **Authentication**: Bearer token authentication
- **Data Format**: JSON API responses
- **File Upload**: FormData support for file attachments
- **Error Handling**: Structured error responses with validation

### Data Models
- **User Model**: User profile and authentication data
- **Account Model**: Financial account information
- **Transaction Model**: Income, expense, and transfer records
- **Budget Model**: Budget configuration and tracking
- **Category Model**: Transaction categorization
- **Currency Model**: Multi-currency support

## Key Functionalities

### Transaction Processing
- Real-time transaction recording with immediate balance updates
- Automatic categorization with custom category support
- Recurring transaction setup for regular income/expenses
- Transfer handling with currency conversion

### Budget Monitoring
- Automatic expense tracking against budget limits
- Percentage-based progress indicators
- Customizable notification thresholds
- Period-based budget cycles (daily, weekly, monthly)

### Data Visualization
- Interactive charts showing spending trends
- Category-wise expense breakdown
- Account balance evolution over time
- Budget vs actual spending comparisons

### Multi-Account Support
- Unlimited account creation
- Different account types (savings, checking, credit, etc.)
- Cross-account transfers with exchange rate handling
- Individual account balance tracking

## Installation & Setup

1. **Prerequisites**
   ```bash
   Flutter SDK (3.0+)
   Dart SDK
   Android Studio / VS Code
   ```

2. **Clone Repository**
   ```bash
   git clone [repository-url]
   cd monet
   ```

3. **Install Dependencies**
   ```bash
   flutter pub get
   ```

4. **Configure API**
   - Update API endpoints in `lib/services/api_routes.dart`
   - Configure base URL for your Laravel API

5. **Run Application**
   ```bash
   flutter run
   ```

## Dependencies

- **flutter**: UI framework
- **hive_flutter**: Local database
- **dio**: HTTP client
- **fl_chart**: Chart library
- **intl**: Internationalization
- **material_design**: UI components

## API Integration

The app integrates with a Laravel-based API providing:
- User authentication and profile management
- Account and transaction CRUD operations
- Budget creation and monitoring
- Category management
- Currency conversion services
- Real-time balance calculations

## Contributing

This project follows Flutter development best practices with clear separation of concerns between UI, business logic, and data layers.

---

**MONET** - Simplifying personal finance management through intuitive design and powerful features.
