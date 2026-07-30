# frozen_string_literal: true

# Read API for service configuration
#
# Each method defines its own fallback chain, from:
#
#   Settings.x.presence  user-editable configuration in the Settings model
#   ENV["X"].presence    environment variable
#   credentials.x        secret from config/credentials/development.yml.enc
#
# Rails secrets are not used in production, so in that case everything should
# come from the environment.
#
# Database and storage config and the like do not use the Settings model, as
# it is unavailable during boot, when those config values are used.
#
require "active_support"
require "active_support/core_ext/object/blank"

module AppConfig

    module_function

    # Course content repository: url/branch are admin-editable
    def github_url    = Settings.git_repo.presence || ENV["GITHUB_BASE"].presence || credentials.github_base
    def github_branch = Settings.git_branch.presence || ENV["GITHUB_BRANCH"].presence || credentials.github_branch
    def github_token  = ENV["GITHUB_TOKEN"].presence || credentials.github_token

    # OpenID connect config
    def oidc_host          = ENV["OIDC_HOST"].presence || credentials.oidc_host
    def oidc_client_id     = ENV["OIDC_CLIENT_ID"].presence || credentials.oidc_client_id
    def oidc_client_secret = ENV["OIDC_CLIENT_SECRET"].presence || credentials.oidc_client_secret
    def oidc_configured?   = oidc_host.present? && oidc_client_id.present? && oidc_client_secret.present?

    # SMTP mail config
    def mailer_address  = ENV["MAILER_ADDRESS"].presence || credentials.mailer_address
    def mailer_domain   = ENV["MAILER_DOMAIN"].presence || credentials.mailer_domain
    def mailer_user     = ENV["MAILER_USER"].presence || credentials.mailer_user
    def mailer_password = ENV["MAILER_PASS"].presence || credentials.mailer_pass

    # From address for e-mails, user-configurable
    def mailer_from = Settings.mailer_from.presence || ENV["MAILER_FROM"].presence ||
                      credentials.mailer_from

    # Code autocheck server
    def check_server_url         = ENV["CHECK_SERVER_URL"].presence || credentials.check_server_url
    def check_server_secret      = ENV["CHECK_SERVER_SECRET"].presence || credentials.check_server_secret
    def check_server_configured? = check_server_url.present? && check_server_secret.present?

    # Plagiarism check server
    def plag_server_key = ENV["PLAG_SERVER_KEY"].presence || credentials.plag_server_key

    # Exam application
    def exam_base_url = ENV["COURSE_SITE_EXAM_SERVER"].presence ||
                        credentials.course_site_exam_server.presence ||
                        "https://ide.proglab.nl/exam.html"

    # Hands application
    def hands_embed_url  = Settings.hands_embed_url.presence || ENV["HANDS_EMBED_URL"].presence ||
                           credentials.hands_embed_url
    def hands_embed_slug = Settings.hands_embed_slug.presence || ENV["HANDS_EMBED_SLUG"].presence ||
                           credentials.hands_embed_slug
    def hands_embed_site_label = Settings.hands_embed_site_label.presence ||
                                 ENV["HANDS_EMBED_SITE_LABEL"].presence ||
                                 credentials.hands_embed_site_label
    def hands_embed_secret = Settings.hands_embed_secret.presence ||
                             ENV["HANDS_EMBED_SECRET"].presence ||
                             credentials.hands_embed_secret

    # These are more or less utilities for database.yml
    def database_name     = ENV["DATABASE_NAME"].presence || credentials.database_name
    def database_user     = ENV["DATABASE_USER"].presence || credentials.database_user
    def database_password = ENV["DATABASE_PASSWORD"].presence || credentials.database_password
    def database_configured? = ENV["DATABASE_URL"].present?

    # Azure config
    def azure_storage_account    = ENV["AZURE_STORAGE_ACCOUNT"].presence || credentials.azure_storage_account
    def azure_storage_access_key = ENV["AZURE_STORAGE_ACCESS_KEY"].presence || credentials.azure_storage_access_key
    def azure_storage_container  = ENV["AZURE_STORAGE_CONTAINER"].presence || credentials.azure_storage_container
    def azure_storage_configured? = azure_storage_account.present? &&
                                    azure_storage_access_key.present? &&
                                    azure_storage_container.present?

    # Shortcut for above
    def credentials = Rails.application.credentials

end
