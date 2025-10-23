class CourseSiteHtml < Kramdown::Converter::Html
    def initialize(root, options)
        super
        @view = options[:context]
    end

    # wrap tables in a div for responsive scrolling
    def convert_table(el, indent)
        "<div class='table-responsive'>#{super}</div>"
    end

    # prefixes all local image src with the right directory in /public/course
    def convert_img(el, indent)
        if el.attr["alt"] == "embed"
            return "<div class='embed' #{html_attributes(el.attr.reject { |k, v|k=='src' })}><div class='ratio ratio-16x9'><iframe allowfullscreen src='#{el.attr['src']}'></iframe></div></div>"
        elsif el.attr["src"] && el.attr["src"] !~ /(^[\w]*:|^\/)/
            el.attr["src"] = File.join(@options[:asset_prefix], el.attr["src"])
        end
        super
    end

    # prefixes all local links with the right directory in /public/course
    def convert_a(el, indent)
        if el.attr["href"] && el.attr["href"] =~ /exam_button:(.+)/
            exam_name = Regexp.last_match(1)
            pset = Pset.find_by_name(exam_name)
            if pset && pset.exam.present?

                return @view.button_to pset.name.humanize, exam_path(id: pset.exam.id), method: :post, class: 'btn btn-secondary', data: { turbo: false }
            else
                return "Exam button should be here, but exam code could not be found: #{exam_name}"
            end
        end

        # any hrefs not starting with proto: or / or # are relative and
        # will be prefixed
        if el.attr["href"] && el.attr["href"] !~ /(^[\w]+:|^\/|^\#)/
            el.attr["href"] = File.join(@options[:asset_prefix], el.attr["href"])
        end

        # ensure that external links are opened in a new tab or window
        if el.attr["href"] && el.attr["href"] =~ /(^https?:)/
            el.attr["target"] = "_blank"
        end

        super
    end

    def convert_p(el, indent)
        if el.children.length == 1 && el.children.first.type == :img && el.children.first.attr["alt"] == "embed"
            inner(el, indent)
        else
            super
        end
    end
end
