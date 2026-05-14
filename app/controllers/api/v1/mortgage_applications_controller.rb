class Api::V1::MortgageApplicationsController < ApplicationController
  def create
    @mortgage_application = MortgageApplication.new(mortgage_application_params)
    
    if @mortgage_application.save
      render json: serialize_mortgage_application(@mortgage_application), status: :created
    else
      render json: { 
        error: 'Validation failed',
        details: @mortgage_application.errors.full_messages 
      }, status: :unprocessable_content
    end
  end

  def show
    @mortgage_application = MortgageApplication.find(params[:id])
    render json: serialize_mortgage_application(@mortgage_application)
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
    
    render json: serialize_affordability_assessment(@affordability_assessment), status: :created
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Mortgage application not found' }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { 
      error: 'Assessment validation failed',
      details: e.record.errors.full_messages 
    }, status: :unprocessable_content
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

  def serialize_mortgage_application(application)
    {
      id: application.id,
      annual_income: application.annual_income,
      monthly_expenses: application.monthly_expenses,
      deposit_amount: application.deposit_amount,
      property_value: application.property_value,
      term: application.term,
      created_at: application.created_at,
      updated_at: application.updated_at
    }
  end

  def serialize_affordability_assessment(assessment)
    {
      id: assessment.id,
      mortgage_application_id: assessment.mortgage_application_id,
      loan_to_value: assessment.loan_to_value,
      debt_to_income_ratio: assessment.debt_to_income_ratio,
      decision: assessment.decision,
      max_borrowing_estimate: assessment.max_borrowing_estimate,
      explanation: assessment.explanation,
      created_at: assessment.created_at,
      updated_at: assessment.updated_at
    }
  end
end