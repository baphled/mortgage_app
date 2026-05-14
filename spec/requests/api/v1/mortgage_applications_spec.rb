require 'rails_helper'

RSpec.describe "/api/v1/mortgage_applications", type: :request do
  describe "POST /create" do
    context "with valid parameters" do
      let(:valid_params) do
        {
          mortgage_application: {
            annual_income: 75000,
            monthly_expenses: 2000,
            deposit_amount: 50000,
            property_value: 250000,
            term_years: 25
          }
        }
      end

      it "creates a new MortgageApplication" do
        expect {
          post '/api/v1/mortgage_applications', params: valid_params
        }.to change(MortgageApplication, :count).by(1)
      end

      it "returns a created status" do
        post '/api/v1/mortgage_applications', params: valid_params
        expect(response).to have_http_status(:created)
      end

      it "returns the created application" do
        post '/api/v1/mortgage_applications', params: valid_params
        
        json = JSON.parse(response.body)
        expect(json['id']).to be_a(Numeric)
        expect(json['annual_income']).to eq(75000)
        expect(json['monthly_expenses']).to eq(2000)
        expect(json['deposit_amount']).to eq(50000)
        expect(json['property_value']).to eq(250000)
        expect(json['term']).to eq(25)
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          mortgage_application: {
            annual_income: -1000,  # Invalid: must be > 0
            monthly_expenses: 2000,
            deposit_amount: 50000,
            property_value: 250000,
            term_years: 25
          }
        }
      end

      it "does not create a new MortgageApplication" do
        expect {
          post '/api/v1/mortgage_applications', params: invalid_params
        }.not_to change(MortgageApplication, :count)
      end

      it "returns unprocessable entity status" do
        post '/api/v1/mortgage_applications', params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns validation error details" do
        post '/api/v1/mortgage_applications', params: invalid_params
        
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Validation failed')
        expect(json['details']).to include('Annual income must be greater than 0')
      end
    end

    context "with missing required parameters" do
      let(:incomplete_params) do
        {
          mortgage_application: {
            annual_income: 75000,
            # missing monthly_expenses, deposit_amount, property_value, term_years
          }
        }
      end

      it "returns unprocessable entity status" do
        post '/api/v1/mortgage_applications', params: incomplete_params
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when deposit exceeds property value" do
      let(:invalid_params) do
        {
          mortgage_application: {
            annual_income: 75000,
            monthly_expenses: 2000,
            deposit_amount: 300000,  # More than property value
            property_value: 250000,
            term_years: 25
          }
        }
      end

      it "does not create a new MortgageApplication" do
        expect {
          post '/api/v1/mortgage_applications', params: invalid_params
        }.not_to change(MortgageApplication, :count)
      end

      it "returns validation error" do
        post '/api/v1/mortgage_applications', params: invalid_params
        
        json = JSON.parse(response.body)
        expect(json['details']).to include('Deposit amount must not exceed property value')
      end
    end
  end

  describe "GET /show" do
    let!(:mortgage_application) do
      create(:mortgage_application, {
        annual_income: 75000,
        monthly_expenses: 2000,
        deposit_amount: 50000,
        property_value: 250000,
        term: 25
      })
    end

    context "when application exists" do
      it "returns the application" do
        get "/api/v1/mortgage_applications/#{mortgage_application.id}"
        expect(response).to have_http_status(:ok)
        
        json = JSON.parse(response.body)
        expect(json['id']).to eq(mortgage_application.id)
        expect(json['annual_income']).to eq(mortgage_application.annual_income)
        expect(json['monthly_expenses']).to eq(mortgage_application.monthly_expenses)
        expect(json['deposit_amount']).to eq(mortgage_application.deposit_amount)
        expect(json['property_value']).to eq(mortgage_application.property_value)
        expect(json['term']).to eq(mortgage_application.term)
      end
    end

    context "when application does not exist" do
      it "returns not found status" do
        get '/api/v1/mortgage_applications/999999'
        expect(response).to have_http_status(:not_found)
        
        json = JSON.parse(response.body)
        expect(json['error']).to include('not found')
      end
    end
  end

  describe "POST /:id/affordability_assessment" do
    let!(:mortgage_application) do
      create(:mortgage_application, {
        annual_income: 75000,
        monthly_expenses: 2000,
        deposit_amount: 50000,
        property_value: 250000,
        term: 25
      })
    end

    context "when application exists" do
      it "creates an affordability assessment" do
        expect {
          post "/api/v1/mortgage_applications/#{mortgage_application.id}/affordability_assessment"
        }.to change(AffordabilityAssessment, :count).by(1)
      end

      it "returns created status" do
        post "/api/v1/mortgage_applications/#{mortgage_application.id}/affordability_assessment"
        expect(response).to have_http_status(:created)
      end

      it "returns assessment results" do
        post "/api/v1/mortgage_applications/#{mortgage_application.id}/affordability_assessment"
        
        json = JSON.parse(response.body)
        expect(json['id']).to be_a(Numeric)
        expect(json['mortgage_application_id']).to eq(mortgage_application.id)
        expect(json['loan_to_value']).to be_a(Numeric)
        expect(json['debt_to_income_ratio']).to be_a(Numeric)
        expect(json['decision']).to eq('approved').or eq('declined')
        expect(json['max_borrowing_estimate']).to be_a(Numeric)
        expect(json['explanation']).to be_a(String)
      end

      it "associates assessment with the mortgage application" do
        post "/api/v1/mortgage_applications/#{mortgage_application.id}/affordability_assessment"
        
        assessment = AffordabilityAssessment.last
        expect(assessment.mortgage_application_id).to eq(mortgage_application.id)
      end
    end

    context "when application does not exist" do
      it "returns not found status" do
        post '/api/v1/mortgage_applications/999999/affordability_assessment'
        expect(response).to have_http_status(:not_found)
        
        json = JSON.parse(response.body)
        expect(json['error']).to include('not found')
      end
    end
  end
end