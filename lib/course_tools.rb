class CourseTools
	
	#
	#
	# Walks all psets named in course.yml and ranks them in the database
	
	def CourseTools.clean_psets

		# an Array only contains pset names and order
		if Settings['psets'].class == Array
			counter = 1
			Settings['psets'].each do |pset|
				if p = Pset.find_by(name:pset)
					p.update_attribute(:order,counter)
					counter += 1
				end
			end

		# a Hash contains pset names, order and weight!
		elsif Settings['psets'].class == Hash
			counter = 1
			Settings['psets'].each do |pset, weight|
				if p = Pset.find_by(name:pset)
					p.update_attributes(order: counter, weight: weight)
					counter += 1
				end
			end
		end
		
		if Settings['grading'] && Settings['grading']['grades']
			counter = 1
			Pset.update_all(order: nil)
			Settings['grading']['grades'].each do |name, definition|
				p = Pset.where(name: name).first_or_create
				p.update_attribute(:order, counter)
				counter += 1
				# TODO put "automatic" attribute into pset record
				p.update_attribute(:grade_type, definition['type'] || :float)
			end
			# p = Pset.where(name: 'final').first_or_create
			# p.update_attribute(:order, counter)
			# p.update_attribute(:grade_type, :float)
			if Settings['grading']['calculation']
				Settings['grading']['calculation'].each do |name, formula|
					p = Pset.where(name: name).first_or_create
					p.update_attribute(:order, counter)
					p.update_attribute(:grade_type, :float)
				end			
			end
		end

	end
	
end
