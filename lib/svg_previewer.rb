require "mini_magick"

class SvgPreviewer < ActiveStorage::Previewer
    class << self
        def accept?(blob)
            blob.content_type == "image/svg+xml"
        end
    end

    def preview(**options)
        download_blob_to_tempfile do |input|
            convert_svg_to_png input do |output|
                yield io: output, filename: "#{blob.filename.base}.png",
                content_type: "image/png", **options
            end
        end
    end

    private
    def convert_svg_to_png(file, &block)
        begin
            image = instrument("mini_magick") do
                MiniMagick::Image.new(file.path)
            end

            if image.valid?
                image.format "png"
                file = File.open image.path
                begin
                    yield file
                ensure
                    file.close!
                end
            else
                logger.info "Skipping svg to png conversion because ImageMagick doesn't support the file"
                raise ActiveStorage::PreviewError
            end
        rescue MiniMagick::Error => error
            logger.error "Skipping svg to png conversion due to an ImageMagick error: #{error.message}"
            raise ActiveStorage::PreviewError
        end
    end
end
