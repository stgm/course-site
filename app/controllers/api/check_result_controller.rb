class Api::CheckResultController < ApplicationController

    skip_before_action :verify_authenticity_token

    def do
        submit = Submit.find_by_check_token(params["id"])

        unless submit
            head :unauthorized and return
        end

        results = params.require(:result).permit(
            summary: [ :total_check_count, :passed_check_count ],
            runs: [ :name, { results: [ :description, :log, :message, :passed ] } ],
            error: [ :value ]
        )

        submit.register_auto_check_results(results.to_h)
        head :ok
    end

end
