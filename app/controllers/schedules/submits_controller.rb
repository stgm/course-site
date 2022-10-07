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
        @users = @schedule.users.not_staff.where(status: [:active, :registered]).who_did_not_submit(@pset)
        @users.each do |u|
            NonSubmitMailer.new_mail(u, @pset, params[:text]).deliver_later
        end
        redirect_to overview_path(@schedule), notice: "E-mails are being sent to #{@users.count} students from #{@schedule.name}."
    end

    def lock_for_all
        load_schedule
        @pset = Pset.find(params[:pset_id])
        @users = @schedule.users.not_staff.where(status: [:active])
        number = 0
        @users.each do |u|
            submit = u.submits.find_or_create_by(pset: @pset)
            submit.update(locked: true)
            number += 1
        end
        redirect_to overview_path(@schedule), notice: "Assignment #{@pset.name} locked for #{number} #{'student'.pluralize(number)} in #{@schedule.name}."
    end

    def unlock_for_all
        load_schedule
        @pset = Pset.find(params[:pset_id])
        @users = @schedule.users.not_staff.where(status: [:active])
        number = @schedule.submits.where(user: @users, pset: @pset, locked: true).update_all(locked: false)
        redirect_to overview_path(@schedule), notice: "Assignment #{@pset.name} unlocked for #{number} #{'student'.pluralize(number)} in #{@schedule.name}."
    end

end
