class ApplicationMailer < ActionMailer::Base

    default from: ENV['MAILER_FROM']
    helper :application

    def self.available?
        # check if (default) from address is not blank
        default[:from].present?
    end

end
