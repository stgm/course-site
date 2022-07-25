module Authentication
    extend ActiveSupport::Concern

    included do
        helper_method :authenticated?, :logged_in?, :current_user
    end

    # decides if any of the auth methods is satisfied
    # may also be used by controller methods to make decisions
    def authenticated?
        return session[:user_id].present?
    end

    def logged_in?
        return authenticated? && current_user.present?
    end

    def current_user
        @current_user ||= (User.find_by(id: session[:user_id]) || User.new)
        Current.user = @current_user
    end

    # before_action to require at least a confirmed login, but not necessarily a user profile
    def authenticate
        redirect_to root_url if not authenticated?
    end

    # before_action to require a user to be logged in
    def authorize
        redirect_to(root_path) && return if not authenticated?
        redirect_to profile_path if !current_user.valid_profile?
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
