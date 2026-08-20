class HandsEmbedController < ApplicationController

    before_action :authorize
    before_action :require_embed_enabled

    # The JS embed calls this route to generate a token for encrypted
    # communication with the hands widget.
    def token
        slug = AppConfig.hands_embed_slug.to_s
        payload = {
            "email"          => current_user.mail.to_s.downcase,
            "name"           => current_user.name.to_s,
            "student_number" => current_user.student_number.to_s,

            # role transfers to the hands site — it maps course-site's
            # student/assistant/head/admin to hands' own role vocabulary
            "role"           => current_user.role,
            "slug"           => slug,
            "site_label"     => site_label,
            "locale"         => I18n.locale.to_s,

            # single-use marker; the hands app rejects a token whose nonce it has
            # already seen, so a token scraped from a log cannot be replayed
            "nonce"          => SecureRandom.hex(12)
        }

        render json: { token: Embed::Token.encode(payload, AppConfig.hands_embed_secret, slug) }
    end

    private

    def site_label
        AppConfig.hands_embed_site_label.presence || request.host
    end

    def require_embed_enabled
        head :not_found unless Embed::Widget.available? && AppConfig.hands_embed_secret.present?
    end

end
