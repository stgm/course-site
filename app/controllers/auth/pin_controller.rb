class Auth::PinController < ApplicationController

    # Facilitates login by pin, for exams

    def self.available?
        Settings.registration_phase == "exam"
    end

    layout "blank"

    def login
        # pincode form
    end

    def validate
        unless Settings.registration_phase == "exam" && Settings.exam_code
            redirect_to root_url, alert: "No current exam" and return
        end
        unless  params[:exam_code].size >= 5 &&
                params[:pin_code].size == 4 &&
                Settings.exam_code == params[:exam_code] &&
                @user = User.authenticate_by_pin(params[:pin_code])
            redirect_to root_url, alert: "Invalid credentials" and return
        end
        unless @user.status_active?
            redirect_to root_url, alert: "User marked inactive, ask teacher" and return
        end
        unless @user.can_submit?
            redirect_to root_url, alert: "User has no student id to submit with" and return
        end
        if @user.last_known_ip.blank?
            @user.update(last_known_ip: request.remote_ip)
        elsif @user.last_known_ip != request.remote_ip
            redirect_to root_url, alert: "Wrong IP" and return
        end
        session[:user_id] = @user.id
        session[:user_mail] = @user.mail
        redirect_to exams_url
    end

end
