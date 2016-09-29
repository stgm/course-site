class AlertMailer < ActionMailer::Base

	def alert_message(user, alert, from_address)
		mail(
			to: user.mail,
			from: from_address,
			body: alert.body,
			content_type: "text/plain",
			subject: alert.title
		)
	end

end
