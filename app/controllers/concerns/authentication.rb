module Authentication

    include AuthenticationHelper

    # before_action to require at least a confirmed login, but not necessarily a user profile
    def authenticate
        if not authenticated?
            # no cookie means no session was created
            redirect_to auth_open_login_url
        end
    end

    # before_action to require a user to be logged in
    def authorize
        if authenticated?
            if !current_user.valid_profile?
                redirect_to profile_url
            end
        end
    end

    # role-based permissions
    def require_admin
        head :forbidden unless current_user.admin?
    end

    def require_senior
        head :forbidden unless current_user.head? or current_user.admin?
    end

    def require_staff
        head :forbidden unless current_user.admin? or current_user.assistant? or current_user.head?
    end

end
