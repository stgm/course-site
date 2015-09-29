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
		
		if Settings['grading']
			Settings['grading'].each do |type, definition|
				if type == 'calculation' || type == 'formulas'
					# ignore
				else
					definition['grades'].each do |grade,weigth|
						p = Pset.where(name: grade).first_or_create
						p.update_attribute(:order, counter)
						Rails.logger.info definition['type']
						p.update_attribute(:grade_type, definition['type'])
						counter += 1
					end
				end
			end
			p = Pset.where(name: 'final').first_or_create
			p.update_attribute(:order, counter)
			p.update_attribute(:grade_type, :float)
		end

	end
	
end
