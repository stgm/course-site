class SubModule < ApplicationRecord

	serialize :content_links, coder: YAML
	
	def load(content, path)
		self.content_links = prepend_path(content, path)
		self.save!
	end
	
	def prepend_path(content, path)
		return nil if content.blank?
		return content.map{|x| prepend_path(x,path)} if content.class==Array
		return content.map{|k,v| [k,prepend_path(v,path)]}.to_h if content.class==Hash
		return content.first=='/' || content.include?(':') ? content : File.join('/', path, content)
	end

end
