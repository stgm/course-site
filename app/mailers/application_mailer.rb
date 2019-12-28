class ApplicationMailer < ActionMailer::Base
	default from: Settings.mailer_from
	# layout 'mailer'
end
