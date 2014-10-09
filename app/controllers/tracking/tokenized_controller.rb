class Tracking::TokenizedController < ActionController::Base
	
	before_action :require_user
	before_action :admin_rights?, only: [:list_students]
	before_action :create_ping, only: [:ping, :gone, :help]
	
	def identify
		if admin_rights?
			render json: { role: 'assistant' }
		else
			render json: { role: 'student' }
		end
	end
	
	def ping
		current_user.ping.update_attributes!(params.permit(:loca, :locb).merge({active:true}))
		render json: true
	end
	
	def gone
		current_user.ping.update_attribute(:active, false)
		render json: true
	end
	
	def help
		current_user.ping.update_attribute(:help, !!params[:help])
		render json: true
	end
	
	def list_assistants
		result = Ping.active.assistants.map { |a| [a.user.name, a.loca, a.locb, !!a.help, a.updated_at] }
		render json: result
	end
	
	def list_students
		result = Ping.active.students.map { |a| [a.user.name, a.loca, a.locb, !!a.help, a.updated_at] }
		render json: result
	end
	
	private
	
	def create_ping
		current_user.create_ping if !current_user.ping
	end
	
	def admin_rights?
		current_user.is_admin? || current_user.is_assistant?
	end
	
	def require_user
		render json: { error: "Not valid." } if !current_user
	end

	def current_user
		return false if params[:token].blank?
		@current_user ||= User.find_by_token(params[:token])
	end	
	
end
