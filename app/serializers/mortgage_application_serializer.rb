class MortgageApplicationSerializer < ActiveModel::Serializer
  attributes :id, :annual_income, :monthly_expenses, :deposit_amount, 
             :property_value, :term, :created_at, :updated_at

  def term
    object.term
  end
end
