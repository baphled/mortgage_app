class AffordabilityAssessor
  attr_reader :mortgage_application

  # Constants for affordability rules
  MAX_LTV_PERCENT = 80.0
  MAX_DTI_PERCENT = 40.0
  MIN_DEPOSIT_PERCENT = 10.0
  MAX_INCOME_MULTIPLE = 0.35
  MAX_TERM_YEARS = 50

  # Result struct to hold assessment data
  Result = Struct.new(
    :loan_to_value,
    :debt_to_income_ratio,
    :decision,
    :max_borrowing_estimate,
    :explanation,
    keyword_init: true
  ) do
    def approved?
      decision == AffordabilityAssessment::DECISIONS[:approved]
    end
  end

  def initialize(mortgage_application)
    @mortgage_application = mortgage_application
  end

  def call
    calculate_affordability_metrics
    determine_decision
    generate_explanation
    build_result
  end

  private

  def calculate_affordability_metrics
    @ltv = mortgage_application.loan_to_value
    @debt_to_income_ratio = mortgage_application.debt_to_income_ratio
    @max_borrowing_estimate = calculate_max_borrowing
  end

  def calculate_max_borrowing
    monthly_income = mortgage_application.annual_income / 12.0
    # Maximum borrowing: percentage of monthly income over the term
    monthly_income * MAX_INCOME_MULTIPLE * (mortgage_application.term_years * 12)
  end

  def determine_decision
    @approved = ltv_approved? && debt_to_income_approved? && deposit_approved?
    @decision = @approved ? AffordabilityAssessment::DECISIONS[:approved] : AffordabilityAssessment::DECISIONS[:declined]
  end

  def ltv_approved?
    @ltv <= MAX_LTV_PERCENT
  end

  def debt_to_income_approved?
    @debt_to_income_ratio <= MAX_DTI_PERCENT
  end

  def deposit_approved?
    minimum_deposit = mortgage_application.property_value * (MIN_DEPOSIT_PERCENT / 100.0)
    mortgage_application.deposit_amount >= minimum_deposit
  end

  def generate_explanation
    reasons = []

    unless ltv_approved?
      reasons << "LTV ratio (#{@ltv.round(2)}%) exceeds maximum of #{MAX_LTV_PERCENT}%"
    end

    unless debt_to_income_approved?
      reasons << "Debt-to-income ratio (#{@debt_to_income_ratio.round(2)}%) exceeds maximum of #{MAX_DTI_PERCENT}%"
    end

    unless deposit_approved?
      minimum_deposit = mortgage_application.property_value * (MIN_DEPOSIT_PERCENT / 100.0)
      reasons << "Deposit (#{format_currency(mortgage_application.deposit_amount)}) is less than minimum required #{format_currency(minimum_deposit)}"
    end

    if reasons.empty?
      @explanation = "Application meets all affordability criteria: LTV #{@ltv.round(2)}% (≤#{MAX_LTV_PERCENT}%), debt-to-income #{@debt_to_income_ratio.round(2)}% (≤#{MAX_DTI_PERCENT}%), and sufficient deposit."
    else
      @explanation = "Application declined: #{reasons.join('; ')}."
    end
  end

  def build_result
    Result.new(
      loan_to_value: @ltv,
      debt_to_income_ratio: @debt_to_income_ratio,
      decision: @decision,
      max_borrowing_estimate: @max_borrowing_estimate,
      explanation: @explanation
    )
  end

  def format_currency(amount)
    format("%.2f", amount)
  end
end
