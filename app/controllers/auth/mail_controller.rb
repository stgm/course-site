class Auth::MailController < ApplicationController

    def login
        render layout: 'welcome'
    end

    def code
        render layout: 'welcome'
    end

    def create
        session[:login_email] = mail = params[:email].downcase
        code = SecureRandom.hex(3)
        session[:login_secret] = Digest::SHA256.hexdigest(code)
        AuthMailer.with(mail: mail, code: code).login_code.deliver_later
        redirect_to auth_mail_code_path
    end

    def validate
        if session[:login_secret] == Digest::SHA256.hexdigest(params[:code])
            mail = session[:login_email]
            if @user = User.find_by_mail(mail)
                # @user.update(validated: true)
            else
                @user = User.create(mail: mail)#, validated: true)
            end
            clear_session
            session[:user_id] = @user.id
            redirect_to root_url
        end
        clear_session
    end
    
    private

    def user_params
        params.require(:user).permit(:name, :login, :alias)
    end

    def clear_session
        session.delete(:login_secret)
        session.delete(:login_email)
    end

end
