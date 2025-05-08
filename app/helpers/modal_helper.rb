module ModalHelper

    def link_to(name = nil, options = nil, html_options = {}, &block)
        if html_options.include?(:target) && !html_options[:target].in?([ "_new", "_blank" ])
            target = html_options[:target]
            html_options.delete :target
            html_options.deep_merge! ({ data: { 'turbo-frame': target } })
        end
        super(name, options, html_options, &block)
    end

end
