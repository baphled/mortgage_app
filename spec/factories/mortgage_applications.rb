FactoryBot.define do
  factory :mortgage_application do
    annual_income { 75_000 }
    monthly_expenses { 2_500 }
    deposit_amount { 50_000 }
    property_value { 300_000 }
    term_years { 25 }

    # Valid application that should be approved
    trait :approved do
      annual_income { 75_000 }
      monthly_expenses { 2_000 }
      deposit_amount { 60_000 }  # 20% deposit
      property_value { 300_000 }
      term_years { 25 }
    end

    # Application with high LTV (should be declined)
    trait :high_ltv do
      deposit_amount { 20_000 }  # ~6.7% deposit
    end

    # Application with high debt-to-income (should be declined)
    trait :high_debt_to_income do
      monthly_expenses { 4_000 }  # 64% of monthly income
    end

    # Application with insufficient deposit (should be declined)
    trait :insufficient_deposit do
      deposit_amount { 25_000 }  # 8.3% deposit
    end
  end
end
