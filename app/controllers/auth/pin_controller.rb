class Auth::PinController < ApplicationController

    # Facilitates login by pin

    def self.available?
        Settings.registration_phase == 'exam'
    end

    layout 'blank'

    def login
        # pincode form
    end

    def validate
        if  Settings.registration_phase == 'exam' &&
            Settings.exam_code &&
            params[:exam_code].size == 6 &&
            params[:pin_code].size == 4 &&
            Settings.exam_code == params[:exam_code] &&
            @user = User.authenticate_by_pin(params[:pin_code])
                if @user.last_known_ip.blank?
                    @user.update(last_known_ip: request.remote_ip)
                elsif @user.last_known_ip != request.remote_ip
                    redirect_to root_url, alert: "Wrong IP" and return
                end
                session[:user_id] = @user.id
                session[:user_mail] = @user.mail
                redirect_to exams_url
        else
            redirect_to root_url, alert: "Something was wrong"
        end
    end

end
