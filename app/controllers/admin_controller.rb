class AdminController < ApplicationController

    before_action :authorize
    before_action :require_admin

end
