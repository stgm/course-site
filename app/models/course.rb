class Course

	include Singleton

	# instance method
	
	def settings
		# get the data from the general settings model
		Settings.course || {}
	end
	
	# methods for settings that also provide defaults
	
	def self.links
		instance.settings['links'] || {}
	end

	# course.yml may contain a key called "modules" that is a hash of
	# descriptions and links to content, functioning as a main table of
	# contents
	def self.modules
		instance.settings['modules'] || {}
	end
	
	def self.feedback_templates
		instance.settings['feedback_templates'] || []
	end
	
	# methods for settings that are HTML
	
	def self.acknowledgements
		instance.settings['acknowledgements'] && instance.settings['acknowledgements'].join("\n\n").html_safe
	end
	
	def self.license
		instance.settings['license'] && instance.settings['license'].html_safe
	end
	
	# catch-all methods to access any other settings
	
	def self.[](name)
		instance.settings[name]
	end
	
	def self.method_missing(m, *args, &block)
		instance.settings[m.to_s]
	end

end
