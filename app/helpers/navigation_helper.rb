module NavigationHelper

	def current_sections
		if current_user.staff?
			Settings.page_tree || {}
		else
			# TODO hide hidden pages
			Settings.page_tree || {}
		end
	end

	def current_schedule
		# either current user's schedule or just a default for logged-out users
		return @current_schedule ||= current_user.schedule || Schedule.first
	end

	def current_module
		if logged_in? && current_schedule.persisted?
			# if user switched schedules, may lack current_module
			if !valid_current_module?
				current_user.reset_current_module && current_user.save
				@current_module = nil
			end
			return @current_module ||= if current_schedule.self_service
					current_user.current_module || current_schedule.current
				else
					current_schedule.current
				end
		end
	end

	def valid_current_module?
		return false if !current_user.schedule.present?
		return false if current_user.current_module.nil?
		return false if !current_user.staff? && !current_user.current_module.public?
		return true
	end

	def prev_module
		# retrieve previous module from here, accounting for student/admin permissions
		current_user.current_module.previous(current_user.student?)
	end

	def next_module
		# retrieve next module from here, accounting for student/admin permissions
		current_user.current_module.next(current_user.student?)
	end

	def user_designation
		@user_designation ||= current_user.group_name || current_user.schedule_name if Schedule.count > 1
	end

	def alerts_for_current_schedule
		Alert.having_schedule_or_nil(current_schedule).where(published: true)
	end

end
