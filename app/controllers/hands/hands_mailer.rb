class Hands::HandsMailer < ApplicationMailer

    def cancelled(hand, name)
        @login = hand.user.login_id
        @assist_name = name
        mail(
        to: hand.user.mail,
        content_type: "text/plain",
        subject: "Your question about #{hand.subject} was removed from the #{Course.short_name} queue")
    end

end
