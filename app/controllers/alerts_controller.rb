class AlertsController < ApplicationController

	before_action :authorize
	before_action :require_senior

	layout 'modal'

	# GET /alerts
	def index
		@alerts = Alert.all
	end

	# GET /alerts/1
	def show
		set_alert
	end

	# GET /alerts/new
	def new
		@alert = Alert.new
	end

	# GET /alerts/1/edit
	def edit
		set_alert
	end

	# POST /alerts
	def create
		@alert = Alert.new(alert_params)

		if @alert.save
			send_mail if params[:send_mail]
			redirect_to alerts_path
		else
			render :new
		end
	end

	# PATCH/PUT /alerts/1
	def update
		set_alert
		if @alert.update(alert_params)
			send_mail if params[:send_mail]
			redirect_to alerts_path
		else
			render :edit
		end
	end

	# DELETE /alerts/1
	def destroy
		set_alert
		@alert.destroy
		redirect_to alerts_path
	end

	private

	def set_alert
		@alert = Alert.find(params[:id])
	end

	def alert_params
		params.require(:alert).permit(:title, :body, :published, :schedule_id)
	end

	def send_mail
		from = Settings.mailer_from
		if not alert_params[:schedule_id].blank?
			recipients = (Schedule.find(alert_params[:schedule_id]).users.active + Schedule.find(alert_params[:schedule_id]).users.staff).uniq
		else
			recipients = (User.active + User.staff).uniq
		end
		recipients.each do |user|
			AlertMailer.alert_message(user, @alert, from).deliver_later
		end
	end

end
