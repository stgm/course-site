module Embed
    # Basic user info is sent encrypted to the Hands app via query params.
    # Generally this is sent in a user's own session, and the information is
    # not secret to them, per se. However, any proxy logging could catch
    # unencrypted info, so we do it just to be sure.
    #
    # Wire format. MUST stay compatible with the hands app's own implementation
    # of Embed::Token (a frozen ciphertext fixture there guards against drift).
    # Each course domain in the Hands app has its own secret to encrypt with.
    #
    #     base64url(domain slug) + "." + MessageEncryptor blob (url_safe base64)
    #
    module Token
        # 120s of usable lifetime plus 30s of clock skew between the two servers.
        # MessageEncryptor's expiry has no leeway of its own, so a verifier whose
        # clock runs ahead would otherwise reject a freshly minted token.
        TTL = 150

        # We generate the encryption key using OpenSSL's HKDF directly (below).
        # It would be possible to use ActiveSupport::KeyGenerator but our
        # link_secret generated in the Hands app is already a 36-char secure
        # token, and this is a bit faster.
        HKDF_SALT = "hands-embed".freeze
        HKDF_INFO = "aes-256-gcm-v2".freeze

        module_function

        # Note that the course domain slug is included for calculating the
        # signature by passing as a "purpose".
        def encode(payload, secret, slug)
            "#{base64url(slug.to_s)}.#{encryptor(secret).encrypt_and_sign(payload, purpose: slug.to_s, expires_in: TTL)}"
        end

        # Wrap Rails' encryptor. The JSON serializer is chosen explicitly,
        # because otherwise it may vary with Rails defaults (in theory at
        # least).
        def encryptor(secret)
            ActiveSupport::MessageEncryptor.new(
                derive_key(secret), cipher: "aes-256-gcm", serializer: JSON, url_safe: true
            )
        end

        # Calculate the key using OpenSSL. Function is memoized: normally the
        # site uses a single secret over its lifetime.
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
