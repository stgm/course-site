class CheckResultController < ApplicationController
	
	skip_before_action :verify_authenticity_token

	def do
		submit = Submit.find_by_check_token(params["id"])
		if submit
			results = params["result"]
			submit.register_check_results(results.to_json)
			render json: "Hi!"
		else
			render json: "Bye!"
		end
	end

end
