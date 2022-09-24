class Api::CheckResultController < ApplicationController
	
	skip_before_action :verify_authenticity_token

	def do
		submit = Submit.find_by_check_token(params["id"])
		if submit
			results = params["result"]
            results2= results
			# TODO insert validator
			results.permit!
            # submit.register_auto_check_results(results.to_h)
            submit.update!(check_results: [results2, results])
			head :ok
		end
	end

end
