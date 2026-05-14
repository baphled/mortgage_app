FactoryBot.define do
  factory :affordability_assessment do
    association :mortgage_application
    loan_to_value { 75.0 }
    debt_to_income_ratio { 35.0 }
    decision { 'approved' }
    max_borrowing_estimate { 250_000 }
    explanation { 'Application meets all affordability criteria' }
    
    trait :declined do
      decision { 'declined' }
      explanation { 'Application declined due to high LTV ratio' }
    end
  end
end
