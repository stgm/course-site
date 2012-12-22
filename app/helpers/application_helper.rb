module ApplicationHelper

	def markdown(text)
		md = Redcarpet::Markdown.new(Redcarpet::Render::SmartyHTML, :autolink => true, :space_after_headers => true, :superscript => true, :tables => true)
		md.render(text).html_safe
	end
	
end
