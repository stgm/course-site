class ProfileController < ApplicationController

    before_action :authenticate

    include NavigationHelper

    def index
        return head(:not_found) if current_user.valid_profile? && current_user.valid_schedule?
        render layout: "blank"
    end

    def ping
        head :ok
    end

    def prev
        current_user.update(current_module: prev_module) if prev_module
        render partial: "sidebar_content"
    end

    def next
        current_user.update(current_module: next_module) if next_module
        render partial: "sidebar_content"
    end

    def set_module
        current_user
        if mod = ScheduleSpan.accessible.where(id: params[:module]).first
            current_user.update(current_module: mod)
        end
        render partial: "sidebar_content"
    end

    def set_schedule
        current_user.update(schedule_id: params[:schedule_id])
        redirect_back fallback_location: "/"
    end

    def save_progress
        if items = params["progress"]
            items.each do |k, v|
                v = v == "1" if v == "1" or v == "0"
                current_user.progress[k] = v
                current_user.save
            end
        end
        head :ok
    end

    def save # POST
        # remove leading and trailing space to give the user some slack
        params[:user][:name].strip! if params[:user][:name]

        # create user if possible
        user_params = params.require(:user).permit(:name, :pronouns, :schedule_id)
        @user = current_user
        @user.assign_attributes({ schedule_id: Schedule.default.try(:id) }.merge(user_params))
        if @user.save
            redirect_to :root
        else
            render "index", status: :unprocessable_entity
        end
    end

end
