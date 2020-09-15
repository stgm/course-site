class Course::Tools
	
	#
	#
	# Walks all psets named in course.yml and ranks them in the database
	
	def self.clean_psets

		# GRADES
		# checks all grades defined in grading.yml, adds them with config
		if Settings['grading'] && Settings['grading']['grades']
			counter = 1
			Pset.update_all(order: nil)
			Settings['grading']['grades'].each do |name, definition|
				p = Pset.where(name: name).first_or_create
				
				# set order
				p.order = counter
				counter += 1
				
				# add any info from course.yml to the pset config, which already can contain info from submit.yml
				p.config = (p.config || {}).merge(definition || {})
				
				# set a few flags from config for easier queries later on
				p.automatic = p.config.present? && p.config["automatic"].present?
				p.grade_type = definition['type'] || :float
				p.test = definition['is_test'] || false
				p.save
			end

			if Settings['grading']['calculation']
				Settings['grading']['calculation'].each do |name, formula|
					p = Pset.where(name: name).first_or_create
					p.order = counter
					counter += 1
					p.grade_type = :float
					p.save
				end			
			end
		end
		
		# TESTS
		# check if any grades are "tests" (for easy data entry on exams), sets flag
		Settings['tests_present'] = Pset.where(test:true).any?
		
		# PSET MODULES
		# check all module definitions, connect psets to parent psets
		if Settings['grading'] && Settings['grading']['modules']
			Settings['grading']['modules'].each do |name, psets|
				parent_pset = Pset.where(name: name).first_or_create
				psets.each do |pset_name|
					pset = Pset.find_by_name(pset_name)
					pset.update(parent_pset: parent_pset)
				end
			end
		end

	end
	
end
