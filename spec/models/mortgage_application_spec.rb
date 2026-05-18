require 'rails_helper'

RSpec.describe MortgageApplication, type: :model do
  def build_application(overrides = {})
    defaults = {
      annual_income: 75_000,
      monthly_expenses: 2_500,
      deposit_amount: 50_000,
      property_value: 300_000,
      term_years: 25
    }
    MortgageApplication.new(defaults.merge(overrides))
  end

  describe 'associations' do
    it 'destroys dependent affordability assessments' do
      reflection = MortgageApplication.reflect_on_association(:affordability_assessments)
      expect(reflection.options[:dependent]).to eq(:destroy)
    end

    it 'has many affordability assessments' do
      reflection = MortgageApplication.reflect_on_association(:affordability_assessments)
      expect(reflection.macro).to eq(:has_many)
    end
  end

  describe 'validations' do
    it 'is valid with all required attributes' do
      expect(build_application).to be_valid
    end

    describe 'annual_income' do
      it 'is invalid when blank' do
        application = build_application(annual_income: nil)
        application.valid?
        expect(application.errors[:annual_income]).to include("can't be blank")
      end

      it 'is invalid when zero' do
        application = build_application(annual_income: 0)
        application.valid?
        expect(application.errors[:annual_income]).to include('must be greater than 0')
      end

      it 'is invalid when negative' do
        application = build_application(annual_income: -1)
        expect(application).not_to be_valid
      end
    end

    describe 'monthly_expenses' do
      it 'is invalid when blank' do
        application = build_application(monthly_expenses: nil)
        application.valid?
        expect(application.errors[:monthly_expenses]).to include("can't be blank")
      end

      it 'is valid when zero' do
        application = build_application(monthly_expenses: 0)
        expect(application).to be_valid
      end

      it 'is invalid when negative' do
        application = build_application(monthly_expenses: -1)
        expect(application).not_to be_valid
      end
    end

    describe 'deposit_amount' do
      it 'is invalid when blank' do
        application = build_application(deposit_amount: nil)
        application.valid?
        expect(application.errors[:deposit_amount]).to include("can't be blank")
      end

      it 'is invalid when negative' do
        application = build_application(deposit_amount: -1)
        expect(application).not_to be_valid
      end
    end

    describe 'property_value' do
      it 'is invalid when blank' do
        application = build_application(property_value: nil)
        application.valid?
        expect(application.errors[:property_value]).to include("can't be blank")
      end

      it 'is invalid when zero' do
        application = build_application(property_value: 0)
        application.valid?
        expect(application.errors[:property_value]).to include('must be greater than 0')
      end
    end

    describe 'term_years' do
      it 'is invalid when blank' do
        application = build_application(term_years: nil)
        application.valid?
        expect(application.errors[:term_years]).to include("can't be blank")
      end

      it 'is invalid when zero' do
        application = build_application(term_years: 0)
        expect(application).not_to be_valid
      end

      it 'is invalid when greater than 50' do
        application = build_application(term_years: 51)
        expect(application).not_to be_valid
      end

      it 'is invalid when a decimal' do
        application = build_application(term_years: 25.5)
        expect(application).not_to be_valid
      end

      it 'is valid at the maximum of 50' do
        application = build_application(term_years: 50)
        expect(application).to be_valid
      end
    end

    describe '#deposit_must_not_exceed_property_value' do
      context 'when the deposit exceeds the property value' do
        let(:application) do
          build_application(deposit_amount: 300_001, property_value: 300_000)
        end

        before { application.valid? }

        it 'is not valid' do
          expect(application).not_to be_valid
        end

        it 'records the cross-field error on deposit_amount' do
          expect(application.errors[:deposit_amount])
            .to include('must not exceed property value')
        end
      end

      it 'is valid when the deposit equals the property value' do
        # The validator uses strict `>` rather than `>=`, so deposit == property
        # value is permitted (e.g. a cash purchase with the full price as deposit).
        application = build_application(deposit_amount: 300_000, property_value: 300_000)

        application.valid?
        expect(application.errors[:deposit_amount])
          .not_to include('must not exceed property value')
      end

      it 'is valid when the deposit is below the property value' do
        application = build_application(deposit_amount: 50_000, property_value: 300_000)

        expect(application).to be_valid
      end
    end
  end

  describe 'calculations' do
    let(:application) do
      build_application(
        annual_income: 60_000,
        monthly_expenses: 1_500,
        deposit_amount: 40_000,
        property_value: 200_000,
        term_years: 20
      )
    end

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
      application = build_application(property_value: 0)
      expect(application.loan_to_value).to eq(0)
    end

    it 'handles zero annual income gracefully' do
      application = build_application(annual_income: 0)
      expect(application.debt_to_income_ratio).to eq(0)
    end
  end
end
