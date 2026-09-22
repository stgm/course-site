class Auth::PinController < ApplicationController

    # Facilitates login by pin, for exams
    #
    # Note: PIN codes are not meant to be hard to guess or anything
    # the intended use is:
    # - secret exam code only available in exam room
    # - pin is used to identify students uniquely, or, when the exam was
    #   started that way, the student's own student ID
    # - successful logins are locked to ip/machine, unless manually unlocked
    # - student identity is checked with login any time during exam

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
        # a generated code is always four digits; a student ID is whatever the
        # university handed out, so it is only checked for being filled in
        pin_code = params[:pin_code].to_s.strip
        pin_ok = Settings.exam_login_method == "student_number" ? pin_code.present? : pin_code.size == 4

        unless  params[:exam_code].size >= 5 &&
                pin_ok &&
                Settings.exam_code == params[:exam_code] &&
                @user = User.authenticate_by_pin(pin_code)
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
