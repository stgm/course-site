class ApplicationMailer < ActionMailer::Base

    default from: Settings.mailer_from
    helper :application

    def self.available?
        # check if (default) from address is not blank
        default[:from].present?
    end

end
