class Auth::SessionController < ApplicationController

    # def logout
    #     redirect_to root_url
    # end

    def logout
        session.delete('user')
        session.delete(:user_id)
        redirect_to root_url
    end

end
