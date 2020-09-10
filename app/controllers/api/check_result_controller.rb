class Api::CheckResultController < ApplicationController
	
	skip_before_action :verify_authenticity_token

	def do
		submit = Submit.find_by_check_token(params["id"])
		if submit
			results = params["result"]
			# TODO insert validator
			submit.register_auto_check_results(results.permit!)
			head :ok
		end
	end

end
