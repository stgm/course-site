class SubmitCheckJob < ApplicationJob
    queue_as :checks

    # Retries on transient HTTP-ish errors; tune attempts/types as you like
    retry_on(Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET,
             wait: :exponentially_longer, attempts: 5)

    # If the Submit got deleted, just drop the job
    discard_on ActiveRecord::RecordNotFound

    # Perform the actual send; Sender is expected to return the token from the check server
    def perform(submit_id, tool_config:, callback_url:, run_immediately:false)
        submit = Submit.find(submit_id)

        return if !run_immediately && submit.check_token.present? && submit.submitted_at > 5.minutes.ago

        token = nil
        Attachments.new(submit.all_files.to_h).zipped do |zip|
            token = CheckSender.new(zip, tool_config: tool_config, callback_url: callback_url).call
        end

        submit.update!(
          check_token: token,
          submitted_at: Time.current
        )
    end
end
