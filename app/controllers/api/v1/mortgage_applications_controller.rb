class Api::V1::MortgageApplicationsController < ApplicationController
  def create
    @mortgage_application = MortgageApplication.new(mortgage_application_params)
    
    if @mortgage_application.save
      render json: {
        id: @mortgage_application.id,
        annual_income: @mortgage_application.annual_income.to_s,
        monthly_expenses: @mortgage_application.monthly_expenses.to_s,
        deposit_amount: @mortgage_application.deposit_amount.to_s,
        property_value: @mortgage_application.property_value.to_s,
        term: @mortgage_application.term,
        created_at: @mortgage_application.created_at,
        updated_at: @mortgage_application.updated_at
      }, status: :created
    else
      render json: { 
        error: 'Validation failed',
        details: @mortgage_application.errors.full_messages 
      }, status: :unprocessable_entity
    end
  end

  def show
    @mortgage_application = MortgageApplication.find(params[:id])
    render json: {
      id: @mortgage_application.id,
      annual_income: @mortgage_application.annual_income.to_s,
      monthly_expenses: @mortgage_application.monthly_expenses.to_s,
      deposit_amount: @mortgage_application.deposit_amount.to_s,
      property_value: @mortgage_application.property_value.to_s,
      term: @mortgage_application.term,
      created_at: @mortgage_application.created_at,
      updated_at: @mortgage_application.updated_at
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Mortgage application not found' }, status: :not_found
  end

  def affordability_assessment
    @mortgage_application = MortgageApplication.find(params[:id])
    assessment = AffordabilityAssessor.new(@mortgage_application).call
    
    # Save assessment to database
    @affordability_assessment = @mortgage_application.affordability_assessments.create!(
      loan_to_value: assessment.loan_to_value,
      debt_to_income_ratio: assessment.debt_to_income_ratio,
      decision: assessment.decision,
      max_borrowing_estimate: assessment.max_borrowing_estimate,
      explanation: assessment.explanation
    )
    
    render json: {
      id: @affordability_assessment.id,
      mortgage_application_id: @affordability_assessment.mortgage_application_id,
      loan_to_value: @affordability_assessment.loan_to_value.to_s,
      debt_to_income_ratio: @affordability_assessment.debt_to_income_ratio.to_s,
      decision: @affordability_assessment.decision,
      max_borrowing_estimate: @affordability_assessment.max_borrowing_estimate.to_s,
      explanation: @affordability_assessment.explanation,
      created_at: @affordability_assessment.created_at,
      updated_at: @affordability_assessment.updated_at
    }, status: :created
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Mortgage application not found' }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { 
      error: 'Assessment validation failed',
      details: e.record.errors.full_messages 
    }, status: :unprocessable_entity
  end

  private

  def mortgage_application_params
    params.require(:mortgage_application).permit(
      :annual_income,
      :monthly_expenses,
      :deposit_amount,
      :property_value,
      :term_years
    ).transform_keys do |key|
      # Convert term_years to term for the model
      key == 'term_years' ? 'term' : key
    end
  end
end