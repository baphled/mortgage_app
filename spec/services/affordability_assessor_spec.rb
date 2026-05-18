require 'rails_helper'

RSpec.describe AffordabilityAssessor, type: :service do
  describe '#call' do
    subject(:result) { described_class.new(mortgage_application).call }

    context 'when application should be approved' do
      let(:mortgage_application) { create(:mortgage_application, :approved) }

      it 'returns approved decision' do
        expect(result.decision).to eq('approved')
      end

      it 'calculates LTV correctly' do
        expect(result.loan_to_value).to eq(80.0)
      end

      it 'calculates debt-to-income ratio correctly' do
        monthly_income = mortgage_application.annual_income / 12.0
        expected_ratio = (mortgage_application.monthly_expenses / monthly_income) * 100
        expect(result.debt_to_income_ratio).to be_within(0.01).of(expected_ratio)
      end

      it 'calculates max borrowing estimate correctly' do
        monthly_income = mortgage_application.annual_income / 12.0
        expected_max = monthly_income * 0.35 * (mortgage_application.term_years * 12)
        expect(result.max_borrowing_estimate).to be_within(0.01).of(expected_max)
      end

      it 'provides positive explanation' do
        expect(result.explanation).to include('meets all affordability criteria')
      end

      it 'returns approved status' do
        expect(result).to be_approved
      end
    end

    context 'when LTV is too high' do
      let(:mortgage_application) { create(:mortgage_application, :high_ltv) }

      it 'returns declined decision' do
        expect(result.decision).to eq('declined')
      end

      it 'explains LTV rejection in explanation' do
        expect(result.explanation).to include('LTV ratio')
      end

      it 'is not approved' do
        expect(result).not_to be_approved
      end
    end

    context 'when debt-to-income ratio is too high' do
      let(:mortgage_application) { create(:mortgage_application, :high_debt_to_income) }

      it 'returns declined decision' do
        expect(result.decision).to eq('declined')
      end

      it 'explains debt-to-income rejection in explanation' do
        expect(result.explanation).to include('Debt-to-income ratio')
      end
    end

    context 'when deposit is insufficient' do
      let(:mortgage_application) { create(:mortgage_application, :insufficient_deposit) }

      it 'returns declined decision' do
        expect(result.decision).to eq('declined')
      end

      it 'explains deposit rejection in explanation' do
        expect(result.explanation).to include('Deposit')
      end
    end

    context 'when multiple criteria fail' do
      let(:mortgage_application) do
        create(:mortgage_application, 
               annual_income: 30_000,
               monthly_expenses: 2_000,
               deposit_amount: 10_000,
               property_value: 200_000,
               term_years: 20)
      end

      it 'returns declined decision' do
        expect(result.decision).to eq('declined')
      end

      it 'explains all failures in explanation' do
        expect(result.explanation).to include('LTV ratio')
        expect(result.explanation).to include('Deposit')
      end
    end

    context 'edge cases' do
      it 'handles zero values gracefully' do
        application = build(:mortgage_application, 
                           annual_income: 1,
                           monthly_expenses: 0,
                           deposit_amount: 1,
                           property_value: 1,
                           term_years: 1)
        
        result = described_class.new(application).call
        expect(result).to be_a(AffordabilityAssessor::Result)
      end
    end
  end
end
