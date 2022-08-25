class Auth::OpenController < ApplicationController

    # Facilitates login by OpenID as configured in the environment

    def self.available?
        ENV['OIDC_CLIENT_ID'].present? &&
        ENV['OIDC_CLIENT_SECRET'].present? &&
        ENV['OIDC_HOST'].present?
    end

    def login
        redirect_to authorization_uri, allow_other_host: true
    end

    def callback
        if params[:error] == 'access_denied'
            redirect_to root_url and return
        end

        # authorization response
        code = params[:code]

        # handle local authentication
        client.authorization_code = code

        begin
            access_token = client.access_token!
        rescue Rack::OAuth2::Client::Error
            # this might happen when we return from the OP and we can't validate
            head(500) and return
        end

        token = access_token.access_token
        info = user_info(token)

        login = info.subject.downcase
        email = info.email
        name = info.nickname

        # for now, prevent any registrations from outside the UvA
        organization = info.raw_attributes['schac_home_organization']
        if organization != 'uva.nl'
            redirect_to root_url, alert: "You can only register for this course using an UvA account."
            return
        end

        # extract UvA student number from string
        student_number =
            info.raw_attributes['schac_personal_unique_code'].try(:first).try do |urn|
                urn.match(/urn:schac:personalUniqueCode:nl:local:uva.nl:studentid:(.*)/).try{|x| x[1]}
            end

        affiliation = JSON(info.raw_attributes['eduperson_affiliation'])

        user_data = {
            login: login,
            name: name,
            mail: email,
            student_number: student_number,
            affiliation: affiliation,
            organization: organization
        }

        # find existing user or create new (if possible)
        if user = User.authenticate(user_data)
            session[:user_id] = user.id
            redirect_to root_url
        else
            redirect_to root_url, alert: "The course has been restricted to not allow everyone to login. Contact your teacher if you think this is in error."
        end
    end

    private

    def client
        @client ||= OpenIDConnect::Client.new(
        identifier: ENV['OIDC_CLIENT_ID'],
        secret: ENV['OIDC_CLIENT_SECRET'],
        redirect_uri: auth_open_callback_url,
        host: ENV['OIDC_HOST'],
        authorization_endpoint: '/oidc/authorize',
        token_endpoint: '/oidc/token',
        userinfo_endpoint: '/oidc/userinfo'
        )
    end

    def authorization_uri
        state = SecureRandom.hex(16)
        nonce = SecureRandom.hex(16)

        client.authorization_uri(
        scope: scope,
        state: state,
        nonce: nonce
        )
    end

    def scope
        default_scope = %w(openid)

        # Add scope for social provider if social login is requested
        if params[:provider].present?
            default_scope << params[:provider]
        else
            default_scope
        end
    end

    def user_info(token)
        return nil unless token.present?

        access_token = OpenIDConnect::AccessToken.new(
        access_token: token,
        client: client
        )

        access_token.userinfo!
    end

end
