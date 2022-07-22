class Auth::SessionController < ApplicationController

    # def logout
    #     redirect_to root_url
    # end

    def logout
        session.delete(:user_id)
        session.delete(:login_secret)
        session.delete(:login_email)
        session.delete(:last_seen_at)
        redirect_to root_url
    end

end
