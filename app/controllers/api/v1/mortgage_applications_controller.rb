class Api::V1::MortgageApplicationsController < ApplicationController
  def create
    @mortgage_application = MortgageApplication.new(mortgage_application_params)

    if @mortgage_application.save
      render json: serialize_mortgage_application(@mortgage_application), status: :created
    else
      render json: {
        error: "Validation failed",
        details: @mortgage_application.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def show
    @mortgage_application = MortgageApplication.find(params[:id])
    render json: serialize_mortgage_application(@mortgage_application)
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Mortgage application not found" }, status: :not_found
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
    render json: { error: "Mortgage application not found" }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      error: "Assessment validation failed",
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
    )
  end

  def serialize_mortgage_application(application)
    {
      data: {
        id: application.id,
        type: "mortgage_application",
        attributes: {
          annual_income: application.annual_income.to_f,
          monthly_expenses: application.monthly_expenses.to_f,
          deposit_amount: application.deposit_amount.to_f,
          property_value: application.property_value.to_f,
          term_years: application.term_years.to_i,
          created_at: application.created_at,
          updated_at: application.updated_at
        }
      }
    }
  end

  def serialize_affordability_assessment(assessment)
    {
      data: {
        id: assessment.id,
        type: "affordability_assessment",
        attributes: {
          mortgage_application_id: assessment.mortgage_application_id,
          loan_to_value: assessment.loan_to_value.to_f,
          debt_to_income_ratio: assessment.debt_to_income_ratio.to_f,
          decision: assessment.decision,
          max_borrowing_estimate: assessment.max_borrowing_estimate.to_f,
          explanation: assessment.explanation,
          created_at: assessment.created_at,
          updated_at: assessment.updated_at
        }
      }
    }
  end
end
