class MortgageApplication < ApplicationRecord
  has_many :affordability_assessments, dependent: :destroy

  validates :annual_income, presence: true, numericality: { greater_than: 0 }
  validates :monthly_expenses, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :deposit_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :property_value, presence: true, numericality: { greater_than: 0 }
  validates :term, presence: true, numericality: { 
    only_integer: true, 
    greater_than: 0,
    less_than_or_equal_to: 50
  }

  validate :deposit_must_not_exceed_property_value

  def loan_amount
    property_value - deposit_amount
  end

  def loan_to_value
    return 0 if property_value.zero?
    (loan_amount / property_value) * 100
  end

  def annual_expenses
    monthly_expenses * 12
  end

  def debt_to_income_ratio
    return 0 if annual_income.zero?
    (annual_expenses / annual_income) * 100
  end

  private

  def deposit_must_not_exceed_property_value
    return if deposit_amount.blank? || property_value.blank?
    
    if deposit_amount > property_value
      errors.add(:deposit_amount, "must not exceed property value")
    end
  end
end