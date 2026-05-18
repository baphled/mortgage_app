class AffordabilityAssessment < ApplicationRecord
  DECISIONS = {
    approved: 'approved',
    declined: 'declined'
  }.freeze

  belongs_to :mortgage_application

  validates :decision, presence: true, inclusion: { in: DECISIONS.values }
  validates :loan_to_value, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :debt_to_income_ratio, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :max_borrowing_estimate, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :explanation, presence: true

  scope :approved, -> { where(decision: DECISIONS[:approved]) }
  scope :declined, -> { where(decision: DECISIONS[:declined]) }
end
