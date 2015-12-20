class AlertMailer < ActionMailer::Base

	def alert_message(user, alert)
		if Settings.mail_address
			mail(
				to: user.mail,
				from: Settings.mail_address,
				body: alert.body,
				content_type: "text/plain",
				subject: alert.title
			)
		end
	end

end
