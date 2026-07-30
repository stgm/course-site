class ApplicationMailer < ActionMailer::Base

    # A Proc, not a plain value: ActionMailer resolves it per message, so an admin changing
    # the address takes effect without a restart. A class-body read would also query the
    # database during boot, since production eager-loads.
    default from: -> { AppConfig.mailer_from },
        "List-Unsubscribe": "<mailto:help@proglab.nl?subject=afmelding%20cursus>",
        "List-Unsubscribe-Post": "List-Unsubscribe=One-Click"

    helper :application

    def self.available?
        AppConfig.mailer_from.present?
    end

end
