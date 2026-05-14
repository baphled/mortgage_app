require 'rails_helper'

RSpec.describe MortgageApplication, type: :model do
  subject(:mortgage_application) { build(:mortgage_application) }

  describe 'associations' do
    it { should have_many(:affordability_assessments).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:annual_income) }
    it { should validate_numericality_of(:annual_income).is_greater_than(0) }
    it { should validate_presence_of(:monthly_expenses) }
    it { should validate_numericality_of(:monthly_expenses).is_greater_than_or_equal_to(0) }
    it { should validate_presence_of(:deposit_amount) }
    it { should validate_numericality_of(:deposit_amount).is_greater_than_or_equal_to(0) }
    it { should validate_presence_of(:property_value) }
    it { should validate_numericality_of(:property_value).is_greater_than(0) }
    it { should validate_presence_of(:term) }
    it { should validate_numericality_of(:term).only_integer.is_greater_than(0) }
  end

  describe 'calculations' do
    let(:application) { build(:mortgage_application, 
                              annual_income: 60_000,
                              monthly_expenses: 1_500,
                              deposit_amount: 40_000,
                              property_value: 200_000,
                              term: 20) }

    describe '#loan_amount' do
      it 'calculates loan amount correctly' do
        expect(application.loan_amount).to eq(160_000)
      end
    end

    describe '#loan_to_value' do
      it 'calculates LTV correctly' do
        expect(application.loan_to_value).to eq(80.0)
      end
    end

    describe '#annual_expenses' do
      it 'calculates annual expenses correctly' do
        expect(application.annual_expenses).to eq(18_000)
      end
    end

    describe '#debt_to_income_ratio' do
      it 'calculates debt-to-income ratio correctly' do
        expect(application.debt_to_income_ratio).to eq(30.0)
      end
    end
  end

  describe 'edge cases' do
    it 'handles zero property value gracefully' do
      application = build(:mortgage_application, property_value: 0)
      expect(application.loan_to_value).to eq(0)
    end

    it 'handles zero annual income gracefully' do
      application = build(:mortgage_application, annual_income: 0)
      expect(application.debt_to_income_ratio).to eq(0)
    end
  end
end
