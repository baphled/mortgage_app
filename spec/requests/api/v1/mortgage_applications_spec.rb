    context "when application does not exist" do
      it "returns not found status" do
        post '/api/v1/mortgage_applications/999999/affordability_assessment'
        expect(response).to have_http_status(:not_found)
        
        json = JSON.parse(response.body)
        expect(json['error']).to include('not found')
      end
    end