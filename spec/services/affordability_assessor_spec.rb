require 'rails_helper'

RSpec.describe AffordabilityAssessor, type: :service do
  def build_application(overrides = {})
    defaults = {
      annual_income: 75_000,
      monthly_expenses: 2_000,
      deposit_amount: 60_000,
      property_value: 300_000,
      term_years: 25
    }
    MortgageApplication.new(defaults.merge(overrides))
  end

  describe '#call' do
    subject(:result) { described_class.new(mortgage_application).call }

    context 'when application should be approved' do
      let(:mortgage_application) { build_application }

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
      let(:mortgage_application) { build_application(deposit_amount: 20_000) }

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
      let(:mortgage_application) { build_application(monthly_expenses: 4_000) }

      it 'returns declined decision' do
        expect(result.decision).to eq('declined')
      end

      it 'explains debt-to-income rejection in explanation' do
        expect(result.explanation).to include('Debt-to-income ratio')
      end
    end

    context 'when deposit is insufficient' do
      let(:mortgage_application) { build_application(deposit_amount: 25_000) }

      it 'returns declined decision' do
        expect(result.decision).to eq('declined')
      end

      it 'explains deposit rejection in explanation' do
        expect(result.explanation).to include('Deposit')
      end
    end

    context 'when multiple criteria fail' do
      let(:mortgage_application) do
        build_application(
          annual_income: 30_000,
          monthly_expenses: 2_000,
          deposit_amount: 10_000,
          property_value: 200_000,
          term_years: 20
        )
      end

      it 'returns declined decision' do
        expect(result.decision).to eq('declined')
      end

      it 'explains the LTV failure in the explanation' do
        expect(result.explanation).to include('LTV ratio')
      end

      it 'explains the deposit failure in the explanation' do
        expect(result.explanation).to include('Deposit')
      end
    end

    context 'edge cases' do
      it 'handles zero values gracefully' do
        application = build_application(
          annual_income: 1,
          monthly_expenses: 0,
          deposit_amount: 1,
          property_value: 1,
          term_years: 1
        )

        result = described_class.new(application).call
        expect(result).to be_a(AffordabilityAssessor::Result)
      end
    end
  end

  describe 'constants' do
    it 'has a maximum LTV of 80%' do
      expect(described_class::MAX_LTV_PERCENT).to eq(80.0)
    end

    it 'has a maximum debt-to-income of 40%' do
      expect(described_class::MAX_DTI_PERCENT).to eq(40.0)
    end

    it 'requires a minimum deposit of 10%' do
      expect(described_class::MIN_DEPOSIT_PERCENT).to eq(10.0)
    end

    it 'uses a max income multiple of 0.35' do
      expect(described_class::MAX_INCOME_MULTIPLE).to eq(0.35)
    end

    it 'caps the mortgage term at 50 years' do
      expect(described_class::MAX_TERM_YEARS).to eq(50)
    end
  end
end
