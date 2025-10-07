module Authentication

    extend ActiveSupport::Concern

    included do
        helper_method :authenticated?, :logged_in?, :current_user
        before_action :current_user
    end

    # decides if any of the auth methods is satisfied
    # may also be used by controller methods to make decisions
    def authenticated?
        return session[:user_id].present? && session[:user_mail].present?
    end

    def logged_in?
        return authenticated? && current_user.persisted?
    end

    def current_user
        if @current_user.blank?
            u = authenticated? && User.find_by(id: session[:user_id], mail: session[:user_mail])
            if User === u
                # got a user object from db
                # auto-assign default schedule upon first user load
                u.set_current_schedule! if u.schedule.blank? && !Schedule.many_registerable?
            else
                # blank user for anonymous session
                u = User.new
            end
            @current_user = u
        end
        Current.user = @current_user
    end

    # before_action to require at least a confirmed login, but not necessarily a user profile
    def authenticate
        redirect_to root_url if not authenticated?
    end

    # before_action to require a user to be logged in
    def authorize
        redirect_to(main_app.root_path) && return if not logged_in?
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

    def require_active_user
        head :forbidden unless current_user.staff? || current_user.can_submit?
    end

end
