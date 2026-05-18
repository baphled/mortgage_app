require 'rails_helper'

RSpec.describe AffordabilityAssessment, type: :model do
  subject(:affordability_assessment) { build(:affordability_assessment) }

  describe 'associations' do
    it { should belong_to(:mortgage_application) }
  end

  describe 'validations' do
    it { should validate_presence_of(:decision) }
    it { should validate_inclusion_of(:decision).in_array(%w[approved declined]) }
    it { should validate_presence_of(:loan_to_value) }
    it { should validate_numericality_of(:loan_to_value).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(100) }
    it { should validate_presence_of(:debt_to_income_ratio) }
    it { should validate_numericality_of(:debt_to_income_ratio).is_greater_than_or_equal_to(0) }
    it { should validate_presence_of(:max_borrowing_estimate) }
    it { should validate_numericality_of(:max_borrowing_estimate).is_greater_than_or_equal_to(0) }
    it { should validate_presence_of(:explanation) }
  end

  describe 'scopes' do
    let!(:approved_assessment) { create(:affordability_assessment, decision: 'approved') }
    let!(:declined_assessment) { create(:affordability_assessment, :declined) }

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
