class AlertsController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin, except: :show

	before_action :set_alert, only: [:show, :edit, :update, :destroy]

	# GET /alerts
	def index
		@alerts = Alert.all
	end

	# GET /alerts/1
	def show
		if request.xhr?
			render :popup, layout: false
		end
	end
	
	# GET /alerts/new
	def new
		@alert = Alert.new
	end

	# GET /alerts/1/edit
	def edit
	end

	# POST /alerts
	def create
		@alert = Alert.new(alert_params)
		
		if @alert.save
			if params[:send_mail]
				from = Settings.mail_address
				User.active.each do |user|
					AlertMailer.alert_message(user, @alert, from).deliver_later
				end
			end

			redirect_to :back, notice: 'Alert was successfully created.'
		else
			render :new
		end
	end

	# PATCH/PUT /alerts/1
	def update
		if @alert.update(alert_params)
			redirect_to @alert, notice: 'Alert was successfully updated.'
		else
			render :edit
		end
	end

	# DELETE /alerts/1
	def destroy
		@alert.destroy
		redirect_to alerts_path, notice: 'Alert was successfully destroyed.'
	end

	private
	# Use callbacks to share common setup or constraints between actions.
	def set_alert
		@alert = Alert.find(params[:id])
	end

	# Only allow a trusted parameter "white list" through.
	def alert_params
		params.require(:alert).permit(:title, :body, :published)
	end

end
