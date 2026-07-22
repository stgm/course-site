module Embed
    # Encrypts the identity assertion that vouches for the logged-in student to
    # the hands app. course-site only ever *mints* tokens — the hands app is the
    # only side that decrypts them — so this is deliberately encode-only.
    #
    # Wire format. MUST stay compatible with the hands app's Embed::Token (a
    # frozen ciphertext fixture there guards against drift):
    #
    #     base64url(slug) + "." + MessageEncryptor blob (url_safe base64)
    #
    # The slug travels in the clear because it is what *selects* the key: the
    # hands app has to know which CourseDomain's link_secret to decrypt with
    # before it can decrypt anything. It is bound into the AEAD as the message
    # purpose, so swapping it invalidates the token.
    #
    # Everything else is encrypted. Encrypting rather than merely signing matters
    # because the token travels in a WebSocket query string (/cable?token=...).
    # Rails filters :token from its own logs, but the reverse proxy in front of
    # the hands app logs full request URIs, and a signed-only payload would put
    # every student's email, name and student number in those logs in plainly
    # decodable base64.
    module Token
        # 120s of usable lifetime plus 30s of clock skew between the two servers.
        # MessageEncryptor's expiry has no leeway of its own, so a verifier whose
        # clock runs ahead would otherwise reject a freshly minted token.
        TTL = 150

        # HKDF, not ActiveSupport::KeyGenerator: link_secret is already a 36-char
        # has_secure_token, so PBKDF2's stretching buys nothing and would cost
        # ~50ms on every mint.
        HKDF_SALT = "hands-embed".freeze
        HKDF_INFO = "aes-256-gcm-v2".freeze

        module_function

        def encode(payload, secret, slug)
            "#{base64url(slug.to_s)}.#{encryptor(secret).encrypt_and_sign(payload, purpose: slug.to_s, expires_in: TTL)}"
        end

        # serializer: JSON is pinned deliberately. MessageEncryptor's default
        # serializer follows each app's config.load_defaults (this app is on 8.0,
        # the hands app on 8.1), so leaving it implicit would make the wire format
        # depend on two Rails versions agreeing.
        def encryptor(secret)
            ActiveSupport::MessageEncryptor.new(
                derive_key(secret), cipher: "aes-256-gcm", serializer: JSON, url_safe: true
            )
        end

        # Memoized: the same handful of secrets are used over and over.
        def derive_key(secret)
            @keys ||= {}
            @keys[secret.to_s] ||=
                OpenSSL::KDF.hkdf(secret.to_s, salt: HKDF_SALT, info: HKDF_INFO, length: 32, hash: "SHA256")
        end

        def base64url(bytes)
            Base64.urlsafe_encode64(bytes, padding: false)
        end
    end
end
