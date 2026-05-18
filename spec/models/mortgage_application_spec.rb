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

  subject(:mortgage_application) { build_application }

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
    it { should validate_presence_of(:term_years) }
    it { should validate_numericality_of(:term_years).only_integer.is_greater_than(0) }
    it { should validate_numericality_of(:term_years).is_less_than_or_equal_to(50) }

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
