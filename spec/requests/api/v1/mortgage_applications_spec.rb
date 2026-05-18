require 'rails_helper'

RSpec.describe 'Api::V1::MortgageApplications', type: :request do
  let(:parsed_body) { JSON.parse(response.body) }

  describe 'POST /api/v1/mortgage_applications' do
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

    context 'with valid attributes' do
      it 'returns 201 Created' do
        post '/api/v1/mortgage_applications', params: valid_params, as: :json
        expect(response).to have_http_status(:created)
      end

      it 'persists the application to the database' do
        expect {
          post '/api/v1/mortgage_applications', params: valid_params, as: :json
        }.to change(MortgageApplication, :count).by(1)
      end

      context 'response body' do
        before { post '/api/v1/mortgage_applications', params: valid_params, as: :json }

        it 'wraps the payload in a data envelope' do
          expect(parsed_body).to have_key('data')
        end

        it 'identifies the resource type as mortgage_application' do
          expect(parsed_body['data']['type']).to eq('mortgage_application')
        end

        it 'includes a numeric id' do
          expect(parsed_body['data']['id']).to be_a(Integer)
        end

        it 'echoes the annual_income as a number' do
          expect(parsed_body['data']['attributes']['annual_income']).to eq(75_000.0)
        end

        it 'echoes the monthly_expenses as a number' do
          expect(parsed_body['data']['attributes']['monthly_expenses']).to eq(2_000.0)
        end

        it 'echoes the deposit_amount as a number' do
          expect(parsed_body['data']['attributes']['deposit_amount']).to eq(60_000.0)
        end

        it 'echoes the property_value as a number' do
          expect(parsed_body['data']['attributes']['property_value']).to eq(300_000.0)
        end

        it 'echoes the term_years as an integer' do
          expect(parsed_body['data']['attributes']['term_years']).to eq(25)
        end

        it 'includes a created_at timestamp' do
          expect(parsed_body['data']['attributes']).to have_key('created_at')
        end

        it 'includes an updated_at timestamp' do
          expect(parsed_body['data']['attributes']).to have_key('updated_at')
        end
      end
    end

    context 'when required fields are missing' do
      before do
        post '/api/v1/mortgage_applications',
             params: { mortgage_application: { annual_income: 50_000 } },
             as: :json
      end

      it 'returns 422 Unprocessable Entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'sets the error message to "Validation failed"' do
        expect(parsed_body['error']).to eq('Validation failed')
      end

      it 'returns the validation details as an array' do
        expect(parsed_body['details']).to be_an(Array)
      end

      it 'reports the missing monthly_expenses field' do
        expect(parsed_body['details']).to include(a_string_matching(/Monthly expenses/))
      end

      it 'reports the missing deposit_amount field' do
        expect(parsed_body['details']).to include(a_string_matching(/Deposit amount/))
      end

      it 'reports the missing property_value field' do
        expect(parsed_body['details']).to include(a_string_matching(/Property value/))
      end

      it 'reports the missing term_years field' do
        expect(parsed_body['details']).to include(a_string_matching(/Term years/))
      end

      it 'does not persist anything' do
        expect {
          post '/api/v1/mortgage_applications',
               params: { mortgage_application: {} },
               as: :json
        }.not_to change(MortgageApplication, :count)
      end
    end

    context 'when the mortgage_application root key is missing' do
      before do
        post '/api/v1/mortgage_applications',
             params: { annual_income: 75_000 },
             as: :json
      end

      it 'returns a 4xx client error rather than crashing' do
        expect(response.status).to be_between(400, 499)
      end

      it 'does not persist any record' do
        expect(MortgageApplication.count).to eq(0)
      end
    end

    context 'when annual_income is negative' do
      let(:negative_income_params) do
        {
          mortgage_application: {
            annual_income: -1,
            monthly_expenses: 2_000,
            deposit_amount: 60_000,
            property_value: 300_000,
            term_years: 25
          }
        }
      end

      before { post '/api/v1/mortgage_applications', params: negative_income_params, as: :json }

      it 'returns 422 Unprocessable Entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'reports the annual_income validation error' do
        expect(parsed_body['details']).to include(a_string_matching(/Annual income/))
      end
    end

    context 'when deposit exceeds property value' do
      let(:invalid_params) do
        {
          mortgage_application: {
            annual_income: 75_000,
            monthly_expenses: 2_000,
            deposit_amount: 400_000,
            property_value: 300_000,
            term_years: 25
          }
        }
      end

      before { post '/api/v1/mortgage_applications', params: invalid_params, as: :json }

      it 'returns 422 Unprocessable Entity' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'sets the error message to "Validation failed"' do
        expect(parsed_body['error']).to eq('Validation failed')
      end

      it 'includes the cross-field validation error in details' do
        expect(parsed_body['details'])
          .to include('Deposit amount must not exceed property value')
      end
    end
  end

  describe 'GET /api/v1/mortgage_applications/:id' do
    context 'when the record exists' do
      let!(:application) { create(:mortgage_application) }

      before { get "/api/v1/mortgage_applications/#{application.id}" }

      it 'returns 200 OK' do
        expect(response).to have_http_status(:ok)
      end

      it 'identifies the resource type as mortgage_application' do
        expect(parsed_body['data']['type']).to eq('mortgage_application')
      end

      it 'returns the matching id' do
        expect(parsed_body['data']['id']).to eq(application.id)
      end

      it 'returns the annual_income as a number' do
        expect(parsed_body['data']['attributes']['annual_income']).to eq(application.annual_income.to_f)
      end

      it 'returns the monthly_expenses as a number' do
        expect(parsed_body['data']['attributes']['monthly_expenses']).to eq(application.monthly_expenses.to_f)
      end

      it 'returns the deposit_amount as a number' do
        expect(parsed_body['data']['attributes']['deposit_amount']).to eq(application.deposit_amount.to_f)
      end

      it 'returns the property_value as a number' do
        expect(parsed_body['data']['attributes']['property_value']).to eq(application.property_value.to_f)
      end

      it 'returns the term_years as an integer' do
        expect(parsed_body['data']['attributes']['term_years']).to eq(application.term_years)
      end
    end

    context 'when the record does not exist' do
      before { get '/api/v1/mortgage_applications/999999' }

      it 'returns 404 Not Found' do
        expect(response).to have_http_status(:not_found)
      end

      it 'includes an error key in the body' do
        expect(parsed_body).to have_key('error')
      end

      it 'returns the error as a non-empty string' do
        expect(parsed_body['error']).to be_a(String).and(satisfy { |s| !s.empty? })
      end
    end
  end

  describe 'POST /api/v1/mortgage_applications/:id/affordability_assessment' do
    context 'when the application exists' do
      let!(:application) { create(:mortgage_application, :approved) }

      context 'and the assessment is created' do
        before { post "/api/v1/mortgage_applications/#{application.id}/affordability_assessment" }

        it 'returns 201 Created' do
          expect(response).to have_http_status(:created)
        end

        it 'identifies the resource type as affordability_assessment' do
          expect(parsed_body['data']['type']).to eq('affordability_assessment')
        end

        it 'includes a numeric id' do
          expect(parsed_body['data']['id']).to be_a(Integer)
        end

        it 'references the mortgage application' do
          expect(parsed_body['data']['attributes']['mortgage_application_id']).to eq(application.id)
        end

        it 'returns the loan_to_value as a number' do
          expect(parsed_body['data']['attributes']['loan_to_value']).to be_a(Numeric)
        end

        it 'returns the debt_to_income_ratio as a number' do
          expect(parsed_body['data']['attributes']['debt_to_income_ratio']).to be_a(Numeric)
        end

        it 'returns the decision as a string' do
          expect(parsed_body['data']['attributes']['decision']).to be_a(String)
        end

        it 'returns the max_borrowing_estimate as a number' do
          expect(parsed_body['data']['attributes']['max_borrowing_estimate']).to be_a(Numeric)
        end

        it 'returns the explanation as a string' do
          expect(parsed_body['data']['attributes']['explanation']).to be_a(String)
        end

        it 'returns approved for an applicant meeting all criteria' do
          expect(parsed_body['data']['attributes']['decision']).to eq(AffordabilityAssessment::DECISIONS[:approved])
        end

        it 'explains that the applicant meets all affordability criteria' do
          expect(parsed_body['data']['attributes']['explanation']).to include('meets all affordability criteria')
        end
      end

      it 'persists the assessment' do
        expect {
          post "/api/v1/mortgage_applications/#{application.id}/affordability_assessment"
        }.to change(AffordabilityAssessment, :count).by(1)
      end
    end

    context 'when the application does not exist' do
      before { post '/api/v1/mortgage_applications/999999/affordability_assessment' }

      it 'returns 404 Not Found' do
        expect(response).to have_http_status(:not_found)
      end

      it 'includes an error key in the body' do
        expect(parsed_body).to have_key('error')
      end

      it 'returns the error as a string' do
        expect(parsed_body['error']).to be_a(String)
      end
    end
  end
end
