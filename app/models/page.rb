class Page < ApplicationRecord

	# belongs_to :section, optional: true
	
	has_many :subpages, dependent: :destroy
	has_one  :pset  # should never be destroyed, because may have submits

	# this generates a url friendly part for the page
	# extend FriendlyId
	# friendly_id :title, use: [ :slugged, :scoped ], scope: :section
	# friendly_id :path, use: :slugged

	# Make sure the subpages are always ordered
	default_scope { order(:position, :title) }
	
	def normalize_friendly_id(string)
		string.
		downcase.
		gsub(" ", "-").
		gsub("problem-sets", "psets")
	end

	def public_url
		the_path = ["/course"]
		the_path << Course.submodule if Course.submodule
		the_path << path
		
		return File.join(the_path)
	end
	
	# def self.nested_sections
	# 	# [ ['problems'], ['problems','adventure'], ['lectures'] ]
	# 	x=Page.pluck(:slug).map { |e| e.split('/') }
	# 	nest_sections x
	# end
	#
	# def self.nest_sections(source)
	# 	# collect paths
	# 	x=[]
	# 	source.each do |path|
	# 		x << [nil, path[0]]
	# 		(0...path.size-1).each do |i|
	# 			x << [path[i], path[i+1]]
	# 		end
	# 	end
	# 	# return as hash-array graph
	# 	return bla(x.uniq,nil)[nil]
	# end
	#
	# def self.bla(graph, node)
	# 	nxt=graph.select{|x| x.first==node} # find all nodes reachable from here
	# 	return node if nxt.size == 0
	# 	return { node => nxt.map{|x| bla(graph, x.second)} }
	# end

end
