class AffordabilityAssessmentSerializer < ActiveModel::Serializer
  attributes :id, :loan_to_value, :debt_to_income_ratio, :decision, 
             :max_borrowing_estimate, :explanation, :created_at
end
