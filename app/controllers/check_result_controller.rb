class CheckResultController < ApplicationController
	
	skip_before_action :verify_authenticity_token

	def do
		s = Submit.find_by_check_token(params["id"])
		if s
			results = params["result"]
			s.update({check_results: results.to_json, check_token: nil})
			render json: "Hi!"
		else
			render json: "Bye!"
		end
	end

end
