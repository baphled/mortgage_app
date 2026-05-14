class AffordabilityAssessor
  attr_reader :mortgage_application

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
      decision == 'approved'
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
    @ltv = calculate_ltv
    @debt_to_income_ratio = calculate_debt_to_income_ratio
    @max_borrowing_estimate = calculate_max_borrowing
  end

  def calculate_ltv
    loan_amount = mortgage_application.property_value - mortgage_application.deposit_amount
    return 0 if mortgage_application.property_value.zero?
    (loan_amount / mortgage_application.property_value) * 100
  end

  def calculate_debt_to_income_ratio
    annual_expenses = mortgage_application.monthly_expenses * 12
    return 0 if mortgage_application.annual_income.zero?
    (annual_expenses / mortgage_application.annual_income) * 100
  end

  def calculate_max_borrowing
    monthly_income = mortgage_application.annual_income / 12
    # Maximum borrowing: 35% of monthly income over the term
    monthly_income * 0.35 * (mortgage_application.term * 12)
  end

  def determine_decision
    @approved = ltv_approved? && debt_to_income_approved? && deposit_approved?
    @decision = @approved ? 'approved' : 'declined'
  end

  def ltv_approved?
    @ltv <= 80
  end

  def debt_to_income_approved?
    @debt_to_income_ratio <= 40
  end

  def deposit_approved?
    minimum_deposit = mortgage_application.property_value * 0.10
    mortgage_application.deposit_amount >= minimum_deposit
  end

  def generate_explanation
    reasons = []
    
    unless ltv_approved?
      reasons << "LTV ratio (#{@ltv.round(2)}%) exceeds maximum of 80%"
    end
    
    unless debt_to_income_approved?
      reasons << "Debt-to-income ratio (#{@debt_to_income_ratio.round(2)}%) exceeds maximum of 40%"
    end
    
    unless deposit_approved?
      minimum_deposit = mortgage_application.property_value * 0.10
      reasons << "Deposit (#{format_currency(mortgage_application.deposit_amount)}) is less than minimum required #{format_currency(minimum_deposit)}"
    end

    if reasons.empty?
      @explanation = "Application meets all affordability criteria: LTV #{@ltv.round(2)}% (≤80%), debt-to-income #{@debt_to_income_ratio.round(2)}% (≤40%), and sufficient deposit."
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
    format('%.2f', amount)
  end
end