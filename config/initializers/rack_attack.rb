class Rack::Attack

  # Throttle email requests: prevent inbox flooding.
  # 5 requests per IP per minute.
  throttle("auth/mail/create", limit: 5, period: 1.minute) do |req|
    req.ip if req.path == "/auth/mail/create" && req.post?
  end

  # Throttle OTP validation: 24-bit code space needs brute-force protection.
  # 5 attempts per IP per minute, then blocked until the window resets.
  throttle("auth/mail/validate", limit: 5, period: 1.minute) do |req|
    req.ip if req.path == "/auth/mail/validate" && req.post?
  end

  # Throttle PIN validation: only 10,000 possible PINs.
  # 5 attempts per IP per minute.
  throttle("auth/pin/validate", limit: 2, period: 1.minute) do |req|
    req.ip if req.path == "/auth/pin/validate" && req.post?
  end

  # Return 429 with a plain-text body instead of the default binary response.
  self.throttled_responder = lambda do |_req|
    [429, { "Content-Type" => "text/plain" }, ["Too many requests. Please try again later."]]
  end

end
