CREATE TABLE affordability_assessments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  mortgage_application_id INTEGER NOT NULL,
  loan_to_value DECIMAL(5,2) NOT NULL,
  debt_to_income_ratio DECIMAL(5,2) NOT NULL,
  decision VARCHAR(255) NOT NULL,
  max_borrowing_estimate DECIMAL(12,2) NOT NULL,
  explanation TEXT,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  FOREIGN KEY (mortgage_application_id) REFERENCES mortgage_applications(id)
);