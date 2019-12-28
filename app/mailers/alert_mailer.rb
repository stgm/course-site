class AlertMailer < ApplicationMailer

	def alert_message(user, alert, from_address)
		mail(
			to: user.mail,
			from: from_address,
			body: alert.body,
			content_type: "text/plain",
			subject: "#{Settings['course']['short_name']}: #{alert.title}"
		)
	end

end
