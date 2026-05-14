CREATE TABLE mortgage_applications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  annual_income DECIMAL(12,2) NOT NULL,
  monthly_expenses DECIMAL(12,2) NOT NULL,
  deposit_amount DECIMAL(12,2) NOT NULL,
  property_value DECIMAL(12,2) NOT NULL,
  term INTEGER NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
);