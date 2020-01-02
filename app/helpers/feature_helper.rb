module FeatureHelper
	
	def should_show_groups_in_hands?
		(!Schedule.many? || Settings.hands_groups) && Group.any?
	end
	
end
