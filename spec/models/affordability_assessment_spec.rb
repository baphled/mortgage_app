require 'rails_helper'

RSpec.describe AffordabilityAssessment, type: :model do
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

  def build_assessment(overrides = {})
    defaults = {
      mortgage_application: build_application,
      loan_to_value: 75.0,
      debt_to_income_ratio: 35.0,
      decision: 'approved',
      max_borrowing_estimate: 250_000,
      explanation: 'Application meets all affordability criteria'
    }
    AffordabilityAssessment.new(defaults.merge(overrides))
  end

  def create_assessment(overrides = {})
    assessment = build_assessment(overrides)
    assessment.mortgage_application.save!
    assessment.save!
    assessment
  end

  describe 'associations' do
    it 'belongs to a mortgage application' do
      reflection = AffordabilityAssessment.reflect_on_association(:mortgage_application)
      expect(reflection.macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    describe 'decision' do
      it 'is invalid when blank' do
        assessment = build_assessment(decision: nil)
        assessment.valid?
        expect(assessment.errors[:decision]).to include("can't be blank")
      end

      it 'is invalid when not approved or declined' do
        assessment = build_assessment(decision: 'pending')
        expect(assessment).not_to be_valid
      end

      it 'is valid when approved' do
        assessment = build_assessment(decision: 'approved')
        expect(assessment).to be_valid
      end

      it 'is valid when declined' do
        assessment = build_assessment(
          decision: 'declined',
          explanation: 'Application declined due to high LTV ratio'
        )
        expect(assessment).to be_valid
      end
    end

    describe 'loan_to_value' do
      it 'is invalid when blank' do
        assessment = build_assessment(loan_to_value: nil)
        assessment.valid?
        expect(assessment.errors[:loan_to_value]).to include("can't be blank")
      end

      it 'is invalid when negative' do
        assessment = build_assessment(loan_to_value: -0.1)
        expect(assessment).not_to be_valid
      end

      it 'is invalid when greater than 100' do
        assessment = build_assessment(loan_to_value: 100.1)
        expect(assessment).not_to be_valid
      end

      it 'is valid at 0' do
        assessment = build_assessment(loan_to_value: 0)
        expect(assessment).to be_valid
      end

      it 'is valid at 100' do
        assessment = build_assessment(loan_to_value: 100)
        expect(assessment).to be_valid
      end
    end

    describe 'debt_to_income_ratio' do
      it 'is invalid when blank' do
        assessment = build_assessment(debt_to_income_ratio: nil)
        assessment.valid?
        expect(assessment.errors[:debt_to_income_ratio]).to include("can't be blank")
      end

      it 'is invalid when negative' do
        assessment = build_assessment(debt_to_income_ratio: -0.1)
        expect(assessment).not_to be_valid
      end
    end

    describe 'max_borrowing_estimate' do
      it 'is invalid when blank' do
        assessment = build_assessment(max_borrowing_estimate: nil)
        assessment.valid?
        expect(assessment.errors[:max_borrowing_estimate]).to include("can't be blank")
      end

      it 'is invalid when negative' do
        assessment = build_assessment(max_borrowing_estimate: -1)
        expect(assessment).not_to be_valid
      end
    end

    describe 'explanation' do
      it 'is invalid when blank' do
        assessment = build_assessment(explanation: nil)
        assessment.valid?
        expect(assessment.errors[:explanation]).to include("can't be blank")
      end
    end
  end

  describe 'scopes' do
    let!(:approved_assessment) { create_assessment(decision: 'approved') }
    let!(:declined_assessment) do
      create_assessment(
        decision: 'declined',
        explanation: 'Application declined due to high LTV ratio'
      )
    end

    describe '.approved' do
      it 'includes assessments with the approved decision' do
        expect(described_class.approved).to include(approved_assessment)
      end

      it 'excludes assessments with the declined decision' do
        expect(described_class.approved).not_to include(declined_assessment)
      end
    end

    describe '.declined' do
      it 'includes assessments with the declined decision' do
        expect(described_class.declined).to include(declined_assessment)
      end

      it 'excludes assessments with the approved decision' do
        expect(described_class.declined).not_to include(approved_assessment)
      end
    end
  end

  describe 'DECISIONS constant' do
    it 'exposes the approved decision value' do
      expect(described_class::DECISIONS[:approved]).to eq('approved')
    end

    it 'exposes the declined decision value' do
      expect(described_class::DECISIONS[:declined]).to eq('declined')
    end

    it 'is frozen to prevent mutation' do
      expect(described_class::DECISIONS).to be_frozen
    end
  end
end
