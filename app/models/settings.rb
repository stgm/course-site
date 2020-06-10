class Settings < RailsSettings::CachedSettings
	
	def self.overview_config
		return {} if not self.grading
		
		# determine the categories to show
		overview = self.grading.select { |category, value| value['show_progress'] }
		
		overview.each do |category, content|
			# remove weight 0 and bonus, only select pset names
			content['submits'] = content['submits'].reject { |submit, weight| (weight == 0 || weight == 'bonus') }.keys

			# determine subgrades
			subgrades = []
			show_calculated = false
			content['submits'].each do |submit, weight|
				subgrades += Settings.grading['grades'][submit]['subgrades'].keys if !Settings.grading['grades'][submit]['hide_subgrades']
				show_calculated = true if !Settings.grading['grades'][submit]['hide_calculated']
			end
			content['subgrades'] = subgrades.uniq
			content['show_calculated'] = show_calculated
		end
		
		return overview
	end
	
end
