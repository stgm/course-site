class AskMailer < ActionMailer::Base

	def ask_me_anything(user, question, ip)
		mail(
		to: Settings.mail_address,
		from: user.mail,
		body: question + "\n\n" + "Sent from #{ip}",
		content_type: "text/plain",
		subject: "Question about #{Settings.short_course_name}")
	end

end
