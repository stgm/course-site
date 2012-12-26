module ApplicationHelper
	
	class LocalRender < Redcarpet::Render::SmartyHTML
		
		def initialize(args={})
			@context = args[:context]
			super args
		end
		
		def image(link, title, alt_text)
			return "<img src='#{File.join('/', @context.public_url, link)}' alt='#{alt_text}'>"
			# image_tag File.join('/public', link), { :title => title, :alt => alt_text }
		end
		
	end
	
	def markdown(text, context)
		md = Redcarpet::Markdown.new(LocalRender.new({ :context => context, :autolink => true, :space_after_headers => true, :superscript => true, :tables => true }), { :context => 'context', :autolink => true, :space_after_headers => true, :superscript => true, :tables => true })
		md.render(text).html_safe
	end
	
end
