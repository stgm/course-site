class Api::GitRepoWebhooksController < ApplicationController
    skip_before_action :verify_authenticity_token # For external POSTs

    def receive
        repo = GitRepo.find(params[:id])
        payload = request.body.read
        data = JSON.parse(payload)

        # Only handle push events; you can check headers if you want
        latest_commit = data["head_commit"]
        if latest_commit
            # GitRepo could fetch this info itself; however,
            # we also have it available in the payload
            repo.update!(
                latest_commit_hash: latest_commit["id"],
                latest_commit_message: latest_commit["message"],
                latest_commit_at: latest_commit["timestamp"]
            )
        end

        head :ok
    rescue => e
        Rails.logger.error("Webhook error: #{e.message}")
        head :bad_request
    end
end
