class CourseTools
	
	#
	#
	# Walks all psets named in course.yml and ranks them in the database
	
	def CourseTools.clean_psets

		# the structure of the 'psets' info in course.yml can differ
		if Settings['psets'].class == Array
			# 1: an Array only contains pset names and order
			counter = 1
			Settings['psets'].each do |pset|
				if p = Pset.find_by(name:pset)
					p.update_attribute(:order,counter)
					counter += 1
				end
			end
		elsif Settings['psets'].class == Hash
			# 2: a Hash contains pset names, order and weight!
			counter = 1
			Settings['psets'].each do |pset, weight|
				if p = Pset.find_by(name:pset)
					p.update_attributes(order: counter, weight: weight)
					counter += 1
				end
			end
		end
		
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
		
		# MODULES
		# check all module definitions, make mod objects and connect to psets
		if Settings['grading'] && Settings['grading']['modules']
			Settings['grading']['modules'].each do |name, psets|
				mod = Mod.where(name: name).first_or_create
				mod_pset = Pset.where(name: name).first_or_create
				# mod.update(pset: mod_pset)
				mod_pset.update(mod: mod)
				psets.each do |pset_name|
					pset = Pset.find_by_name(pset_name)
					pset.update(parent_mod: mod)
				end
			end
		end

	end
	
end
