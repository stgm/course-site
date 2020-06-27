class Mod < ApplicationRecord

	has_many :psets # that belong to the module
	belongs_to :pset # to assign grades for this module

	serialize :content_links
	
	def load(content, path)
		self.content_links = prepend_path(content, path)
		self.pset = Pset.where(name: name).first_or_create
		self.save!
	end
	
	def prepend_path(content, path)
		return nil if content.blank?
		return content.map{|x| prepend_path(x,path)} if content.class==Array
		return content.map{|k,v| [k,prepend_path(v,path)]}.to_h if content.class==Hash
		return content.first=='/' ? content : File.join('/', path, content)
	end

end
