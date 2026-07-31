class HandsEmbedController < ApplicationController

    # Mints short-lived signed tokens so the navbar widget can talk to the
    # separate hands app on the student's behalf without exposing the shared
    # secret to the browser. Additive; does not touch the local hands feature.

    before_action :authorize
    before_action :require_embed_enabled

    def token
        slug = AppConfig.hands_embed_slug.to_s
        payload = {
            "email"          => current_user.mail.to_s.downcase,
            "name"           => current_user.name.to_s,
            "student_number" => current_user.student_number.to_s,
            "slug"           => slug,
            "site_label"     => site_label,
            # Hand our language setting over so the widget speaks the course's
            # language (ApplicationController sets this from Course.language).
            "locale"         => I18n.locale.to_s,
            # Single-use marker; the hands app rejects a token whose nonce it has
            # already seen, so a token scraped from a log cannot be replayed.
            "nonce"          => SecureRandom.hex(12)
        }

        # Expiry rides in the encrypted metadata (Embed::Token::TTL) rather than
        # in the payload, so it cannot be read or edited in transit.
        #
        # Only the token is returned: the widget already knows where the hands app
        # lives (window.HandsEmbed), and the slug/site_label travel inside the
        # encrypted payload.
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
