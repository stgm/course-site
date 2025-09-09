class Hands::HandsController < ApplicationController

    include NavigationHelper

    before_action :authorize
    before_action :require_staff

    layout "hands"

    before_action do
        @group_name = params["group"] ||  current_user.groups.first&.name || current_user.full_designation.gsub("\n", " &ndash; ")
        @course_name = Schedule.count > 1 && current_schedule.name || Course.long_name
        @reload_path = hands_path

        I18n.locale = "en"
    end

    def index
        redirect_to edit_hands_availability_path and return unless current_user.senior? || (current_user.available && current_user.available > DateTime.now)

        @title = "Hands"
        if params[:term]
            @users = User.where("name like ?", "%#{params[:term]}%").student
            render "search"
        else
            @my_hands = Hand.where(done: false, assist: current_user).order("created_at asc")
            @hands = Hand.where(done: false, assist: nil).order("hands.created_at asc")
            @long_time_users = User.student
                .where("last_known_location is not null and location_confirmed = ?", false)
                .where("last_seen_at > ? and last_seen_at < ?", 1.hour.ago, 0.minutes.ago)
                .where("last_spoken_at < ? or last_spoken_at is null or location_confirmed = ?", Date.today, false)
                .order("last_spoken_at asc")
            if Settings.hands_groups && params[:group]!="all"
                selected_group = Group.find_by_name(params["group"])
                @group = current_user.groups.first
                @hands = @hands.includes(:user).where(users: { group: selected_group || @group })
                @long_time_users = @long_time_users.where(users: { group: selected_group || @group })
            end
        end
    end

    # showing a hand automatically dibs/claims it, only for assistant users
    def show
        # catch erroneous GET requests for /hands/done
        raise ActionController::RoutingError.new("Huh?") if params[:id] == "done"

        Hand.transaction do
            load_hand
            if current_user.assistant? && @hand.assist != current_user && !@hand.helpline
                if auto_claim_hand
                    # flash[:notice] = "Go and help this one!"
                else
                    # flash[:alert] = "Someone was ahead of you!"
                    redirect_to hands_path and return
                end
            end
        end

        @title = "Hand"
    end

    def new
        load_user
        @title = "Hands"
    end

    def create
        load_user
        create_hand
        redirect_to action: "index", only_path: true
    end

    def confirm_location
        load_user
        @user.confirm_location!(params[:location][:confirmed])
        redirect_back fallback_location: attendance_path
    end

    def clear_all_locations
        User.student.active.where(schedule:current_schedule).update_all(location_confirmed: false)
        redirect_back fallback_location: attendance_path
    end

    def search
    end

    # manual dibs for admins & other situations
    def dib
        Hand.transaction do
            load_hand
            if auto_claim_hand
                # flash[:notice] = "Go and help this one!"
                redirect_back fallback_location: "/"
            else
                # flash[:alert] = "Someone was ahead of you!"
                redirect_to hands_path and return
            end
        end
    end

    def done
        h = Hand.find(params[:id])
        h.update(done: true, success: params[:success], evaluation: params[:evaluation], note: params[:note], progress: params[:progress], closed_at: DateTime.current)
        if not h.success
            Hands::HandsMailer.cancelled(h, current_user.name.split.first).deliver_later
        end
        redirect_to action: "index", only_path: true
    end

    def helpline
        h = Hand.find(params[:id])
        h.update(helpline: true, assist: nil)
        redirect_to action: "index", only_path: true
    end

    private

    def load_user
        @user = User.find(params[:user_id])
    end

    def load_hand
        @hand = Hand.find(params[:id])
    end

    def auto_claim_hand
        if @hand.assist.blank?
            @hand.update(assist_id: current_user.id, claimed_at: DateTime.now)
            return true
        end
    end

    def create_hand
        Hand.create(user_id: @user.id, evaluation: params[:evaluation], note: params[:note], done: true, success: true, assist: current_user, progress: params[:progress], closed_at: DateTime.now, claimed_at: DateTime.now)
    end

end
