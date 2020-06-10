class Course

	include Singleton
	
	def initialize
		@settings = Settings.course
	end
	
	def settings
		@settings || {}
	end
	
	def self.[](name)
		instance.settings[name]
	end
	
	def self.links
		instance.settings['links'] || {}
	end
	
	def self.modules
		instance.settings['modules'] || {}
	end

	def self.feedback_templates
		instance.settings['feedback_templates'] || []
	end
	
	def self.acknowledgements
		instance.settings['acknowledgements'] && instance.settings['acknowledgements'].join("\n\n").html_safe
	end

	def self.license
		instance.settings['license'] && instance.settings['license'].html_safe
	end
	
	def self.method_missing(m, *args, &block)
		instance.settings[m.to_s]
	end

end
