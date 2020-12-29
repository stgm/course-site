class Schedules::SubmitsController < Schedules::ApplicationController

	before_action :authorize
	before_action :require_senior

	layout 'modal'

	# GET /schedules/<slug>/submits/form_for_missing
	def form_for_missing
		load_schedule
		@psets = Pset.all.order(:name)
	end

	# POST /schedules/<slug>/submits/notify_missing
	def notify_missing
		load_schedule
		@pset = Pset.find(params[:pset_id])
		@users = @schedule.users.not_staff.not_inactive.who_did_not_submit(@pset)
		@users.each do |u|
			NonSubmitMailer.new_mail(u, @pset, params[:text]).deliver_later
		end
		redirect_to schedule_overview_path(@schedule), notice: "E-mails are being sent to #{@users.count} students from #{@schedule.name}."
	end

end
