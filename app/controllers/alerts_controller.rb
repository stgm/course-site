class AlertsController < ModalController

	before_action :authorize
	before_action :require_senior
	before_action :load_navigation
	
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
			respond_to do |format|
				format.js { go_to_index }
				format.html { redirect_back fallback_location: '/', notice: 'Alert was successfully created.' }
			end
		else
			render :new
		end
	end

	# PATCH/PUT /alerts/1
	def update
		set_alert
		if @alert.update(alert_params)
			send_mail if params[:send_mail]
			respond_to do |format|
				format.js { go_to_index }
				format.html { redirect_to @alert, notice: 'Alert was successfully updated.' }
			end
		else
			render :edit
		end
	end

	# DELETE /alerts/1
	def destroy
		set_alert
		@alert.destroy
		
		respond_to do |format|
			format.js { go_to_index }
			format.html { redirect_to alerts_path, notice: 'Alert was successfully destroyed.' }
		end
	end

	private
	
	# Use callbacks to share common setup or constraints between actions.
	def set_alert
		@alert = Alert.find(params[:id])
	end

	# Only allow a trusted parameter "white list" through.
	def alert_params
		params.require(:alert).permit(:title, :body, :published, :schedule_id)
	end
	
	def send_mail
		from = Settings.mailer_from
		if not alert_params[:schedule_id].blank?
			recipients = (Schedule.find(alert_params[:schedule_id]).users.not_inactive + Schedule.find(alert_params[:schedule_id]).users.staff).uniq
		else
			recipients = (User.not_inactive + User.staff).uniq
		end
		recipients.each do |user|
			AlertMailer.alert_message(user, @alert, from).deliver_later
		end
	end
	
	def go_to_index
		index
		render 'index'
	end

end
