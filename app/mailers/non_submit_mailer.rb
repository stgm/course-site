class NonSubmitMailer < ApplicationMailer

	def new_mail(user, pset, notice)
		grade_name = pset.name
		login = user.login_id
		mail(
			to: user.mail,
			subject: "#{Settings.short_course_name}: submit #{grade_name}!",
			body: "#{notice}\n\n\n#{login}"
		)
	end
	
end
