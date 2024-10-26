module Plugins
  module Exam
    class Admin::ExamsController < Plugins::Exam::ApplicationController

      before_action :authorize
      before_action :require_admin

      layout 'modal'

      def index
        @exams = Exam.includes(:pset).order('psets.name')
      end

      def edit
        @exam = Exam.find(params[:id])
      end

      def update
        @exam = Exam.find(params[:id])

        params.permit!

        params[:exam][:config][:files] = params[:exam][:config][:files].select { |i| i['name'].present? }
        params[:exam][:config][:buttons] = params[:exam][:config][:buttons].select { |i| i['name'].present? }

        if @exam.update(params[:exam])
          redirect_to admin_exams_path
        else
          render :show
        end
      end

      def list_codes
        @users = User.includes(:group, :schedule).not_admin
        @groups = User.includes(:group, :schedule).not_admin.order('schedules.name, groups.name, users.name').group_by { |u| [u.schedule_name, u.group_name] }
        render layout: false
      end

      def run_checks
        # run checks for all unchecked submissions for an exam
        # use the exam check config
        # refactor check running in pset(?)
      end

    end
  end
end
