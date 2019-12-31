class Schedules::SubmitsController < ApplicationController

	before_action :authorize
	before_action :require_senior

	# GET /schedules/.../submits/form_for_missing
	def form_for_missing
		load_navigation
		@schedule = current_user.schedule
		@users = @schedule.users.not_staff.not_inactive
		@psets = Pset.all
		render layout: "application"
	end

	# POST /schedules/.../submits/notify_missing
	def notify_missing
		@schedule = current_user.schedule
		@pset = Pset.find(params[:pset_id])
		@users = @schedule.users.not_staff.not_inactive

		@users.each do |u|
			if !@pset.submit_from(u)
				NonSubmitMailer.new_mail(u, @pset, params[:text]).deliver_later
			end
		end
		redirect_to @schedule, notice: 'E-mails are being sent.'
	end
	
end
