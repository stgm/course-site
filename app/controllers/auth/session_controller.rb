class Auth::SessionController < ApplicationController

    def logout
        reset_session
        redirect_to root_url
    end

end
