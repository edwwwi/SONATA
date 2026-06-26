# POS System

A modern offline Point of Sale (POS) and Inventory Management System built for small and medium-sized retail businesses.

The application is designed to provide a simple, fast, and reliable billing experience while maintaining accurate inventory records. All data is stored locally using SQLite, allowing the software to operate completely offline without requiring internet access, subscriptions, or cloud services.

---

## Features

### Billing Management

* Fast and intuitive billing interface
* Product-based billing workflow
* Automatic bill generation
* Sales history tracking

### Inventory Management

* Product management
* Stock tracking
* Stock addition and updates
* Automatic stock deduction after sales
* Stock movement history

### Reports

* Daily sales reports
* Sales history
* Stock reports
* PDF report generation
* CSV export functionality

### Security

* Owner PIN protected reports section
* Restricted access to sales and stock information

### Offline First

* Fully offline operation
* Local SQLite database
* No cloud dependency
* No internet connection required

---

## Technology Stack

| Layer            | Technology        |
| ---------------- | ----------------- |
| Frontend         | Flutter Desktop   |
| State Management | Riverpod          |
| Database         | SQLite            |
| Reporting        | PDF Package       |
| Export           | CSV               |
| Storage          | Local File System |

---

## Project Structure

```text
lib/
├── core/
├── models/
├── services/
├── repositories/
├── screens/
├── widgets/
├── database/
└── utils/
```

---

## Core Modules

### Billing

Manage customer purchases and generate bills.

### Products

Create, update, and manage product information.

### Inventory

Track stock levels and maintain stock movement records.

### Reports

Generate sales and inventory reports with export functionality.

### Settings

Manage application settings and owner PIN.

---

## Database Tables

### Products

Stores product information.

### Sales

Stores completed sales transactions.

### Sale Items

Stores individual items within a sale.

### Stock Movements

Tracks stock additions and deductions.

### Settings

Stores application configurations and owner PIN.

---

## Future Enhancements

* Barcode Scanner Support
* Thermal Printer Support
* Product Categories
* Low Stock Alerts
* Database Backup & Restore
* Dashboard Analytics
* Multi-device Synchronization

---

## Goals

* Simple and easy-to-use interface
* Touch-friendly design
* Fast billing workflow
* Accurate inventory management
* Reliable offline operation
* Minimal maintenance requirements

---

## License

This project is licensed under the MIT License.
