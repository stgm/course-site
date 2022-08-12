class AuthMailer < ApplicationMailer

    # Subject can be set in your I18n file at config/locales/en.yml
    # with the following lookup:
    #
    #   en.notifications_mailer.login.subject
    #
    def login_code
        @email = params[:mail]
        @code = params[:code]
        mail to: @email, subject: "Login voor het Programmeerlab"
    end

end
