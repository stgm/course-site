class AlertMailer < ApplicationMailer

    def alert_message(user, alert)
        mail(
        to: user.mail,
        body: alert.body,
        content_type: "text/plain",
        subject: "#{Course.short_name}: #{alert.title}"
        )
    end

end
