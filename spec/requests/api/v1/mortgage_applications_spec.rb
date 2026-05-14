require 'rails_helper'

RSpec.describe '/api/v1/mortgage_applications', type: :request do
  describe 'POST /create' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          mortgage_application: {
            annual_income: 75_000,
            monthly_expenses: 2_000,
            deposit_amount: 60_000,
            property_value: 300_000,
            term_years: 25
          }
        }
      end

      it 'creates a new MortgageApplication' do
        expect {
          post '/api/v1/mortgage_applications', params: valid_params
        }.to change(MortgageApplication, :count).by(1)
      end

      it 'returns a created status' do
        post '/api/v1/mortgage_applications', params: valid_params
        expect(response).to have_http_status(:created)
      end

      it 'returns the created application' do
        post '/api/v1/mortgage_applications', params: valid_params
        json = JSON.parse(response.body)
        expect(json['annual_income']).to eq('75000.0')
        expect(json['deposit_amount']).to eq('60000.0')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          mortgage_application: {
            annual_income: -1000,  # Invalid negative income
            monthly_expenses: 2_000,
            deposit_amount: 60_000,
            property_value: 300_000,
            term_years: 25
          }
        }
      end

      it 'does not create a new MortgageApplication' do
        expect {
          post '/api/v1/mortgage_applications', params: invalid_params
        }.not_to change(MortgageApplication, :count)
      end

      it 'returns unprocessable entity status' do
        post '/api/v1/mortgage_applications', params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns validation error details' do
        post '/api/v1/mortgage_applications', params: invalid_params
        json = JSON.parse(response.body)
        expect(json['error']).to include('Validation failed')
        expect(json['details']).to be_an(Array)
      end
    end

    context 'with missing required parameters' do
      let(:missing_params) do
        {
          mortgage_application: {
            annual_income: 75_000,
            monthly_expenses: 2_000
            # Missing deposit_amount, property_value, term_years
          }
        }
      end

      it 'returns unprocessable entity status' do
        post '/api/v1/mortgage_applications', params: missing_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET /show' do
    let!(:mortgage_application) { create(:mortgage_application) }

    context 'when application exists' do
      it 'returns the application' do
        get "/api/v1/mortgage_applications/#{mortgage_application.id}"
        expect(response).to have_http_status(:ok)
        
        json = JSON.parse(response.body)
        expect(json['id']).to eq(mortgage_application.id)
        expect(json['annual_income']).to eq(mortgage_application.annual_income.to_s)
      end
    end

    context 'when application does not exist' do
      it 'returns not found status' do
        get '/api/v1/mortgage_applications/999999'
        expect(response).to have_http_status(:not_found)
        
        json = JSON.parse(response.body)
        expect(json['error']).to include('not found')
      end
    end
  end

  describe 'POST /:id/affordability_assessment' do
    let!(:mortgage_application) { create(:mortgage_application) }

    context 'when application exists' do
      it 'creates an affordability assessment' do
        expect {
          post "/api/v1/mortgage_applications/#{mortgage_application.id}/affordability_assessment"
        }.to change(AffordabilityAssessment, :count).by(1)
      end

      it 'returns created status' do
        post "/api/v1/mortgage_applications/#{mortgage_application.id}/affordability_assessment"
        expect(response).to have_http_status(:created)
      end

      it 'returns assessment results' do
        post "/api/v1/mortgage_applications/#{mortgage_application.id}/affordability_assessment"
        json = JSON.parse(response.body)
        
        expect(json['loan_to_value']).to be_a(String)
        expect(json['debt_to_income_ratio']).to be_a(String)
        expect(json['decision']).to be_in(['approved', 'declined'])
        expect(json['explanation']).to be_a(String)
      end

      it 'associates assessment with the mortgage application' do
        post "/api/v1/mortgage_applications/#{mortgage_application.id}/affordability_assessment"
        
        assessment = AffordabilityAssessment.last
        expect(assessment.mortgage_application_id).to eq(mortgage_application.id)
      end
    end

    context 'when application does not exist' do
      it 'returns not found status' do
        post '/api/v1/mortgage_applications/999999/affordability_assessment'
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
