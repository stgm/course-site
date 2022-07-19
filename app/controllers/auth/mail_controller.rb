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
            logger.info "FOUND MAIL"
            logger.info mail
            if @user = User.find_by_mail(mail)
                logger.info "ALSO IN DB"
                # @user.update(validated: true)
            else
                logger.info "CREATING NEW"
                @user = User.create(mail: mail)#, validated: true)
            end
            session[:user_id] = @user.id
            redirect_to root_url
        end
    end
    
    private

    def user_params
        params.require(:user).permit(:name, :login, :alias)
    end

end
