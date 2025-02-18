class Admin::UsersController < ApplicationController

    include ApplicationHelper

    before_action :authorize
    before_action :require_admin

    layout "modal"

    # Show user permissions modal.
    def index
        @users = User.staff.order(:role, :name)
        @schedules = Schedule.order(:name)
        @groups = Group.includes(:schedule).order("schedules.name").order("groups.name")
    end

    def new
        @user = User.new
        if params[:multiple]
            render "new_multiple"
        else
            render "new"
        end
    end

    # Create a new user if self-signups are not allowed.
    def create
        if params[:user][:infos]
            # bulk user invite, assume everything is valid
            params[:user][:infos].split("\n").each do |user_info|
                if user_info.strip.size > 0
                    parsed = user_info.match /(?:"?([^"]*?)"?\s*)?<\s*(.+@[^> ]+)\s*>/
                    name = parsed[1]
                    mail = parsed[2]
                    begin
                        User.create!(name: name, mail: mail, schedule_id: params[:user][:schedule_id], role: params[:user][:role])
                    rescue ActiveRecord::RecordNotUnique
                        if u = User.find(mail: mail)

                        end
                    end
                end
            end
            redirect_to admin_course_path
        else
            # single user invite
            @user = User.new(params.require(:user).permit(:name, :mail, :role, :schedule_id))
            if @user.save
                redirect_to user_path(@user.id)
            else
                render "new"
            end
        end
    end

    # Sets or unsets user role.
    def set_role
        user = User.find(params[:user_id])
        user.update!(params.require(:user).permit(:role))
        redirect_to user
    end

    def add_group_permission
        load_user
        load_group
        @user.groups << @group unless @user.groups.include?(@group)
        redirect_to admin_users_path
    end

    def remove_group_permission
        load_user
        load_group
        @user.groups.delete(@group)
        redirect_to admin_users_path
    end

    def add_schedule_permission
        load_user
        load_schedule
        @user.schedules << @schedule unless @user.schedules.include?(@schedule)
        redirect_to admin_users_path
    end

    def remove_schedule_permission
        load_user
        load_schedule
        @user.schedules.delete(@schedule)
        redirect_to admin_users_path
    end

    private

    def load_user
        @user = User.find(params[:user_id])
    end

    def load_group
        @group = Group.friendly.find(params[:group_id])
    end

    def load_schedule
        @schedule = Schedule.friendly.find(params[:schedule_id])
    end

end
