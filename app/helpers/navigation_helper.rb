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
		return @current_schedule ||= current_user.schedule || Schedule.find_or_initialize_by(name: 'Standard', slug: 'standard')
	end

	def current_module
		if current_schedule
			# if user switched schedules, may lack current_module TODO move to user model on change schedule
			current_user.check_current_module
			return @current_module ||= if current_schedule.self_service
					current_user.current_module || current_schedule.current
				else
					current_schedule.current
				end
		end
	end

	def user_designation
		@user_designation ||= current_user.group_name || current_user.schedule_name if Schedule.count > 1
	end

	def alerts_for_current_schedule
		Alert.having_schedule_or_nil(current_schedule).where(published: true)
	end

end
