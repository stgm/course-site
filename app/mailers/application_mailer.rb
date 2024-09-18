class ApplicationMailer < ActionMailer::Base

    default from: ENV['MAILER_FROM'],
        "List-Unsubscribe": "<mailto:help@proglab.nl?subject=afmelding%20cursus>",
        "List-Unsubscribe-Post": "List-Unsubscribe=One-Click"

    helper :application

    def self.available?
        # check if (default) from address is not blank
        default[:from].present?
    end

end
