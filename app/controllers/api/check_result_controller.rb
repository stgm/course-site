class Api::CheckResultController < ApplicationController
	
	skip_before_action :verify_authenticity_token

	def do
		submit = Submit.find_by_check_token(params["id"])
		if submit
			results = params["result"]
			submit.register_auto_check_results(results)
			head :ok
		end
	end

end
