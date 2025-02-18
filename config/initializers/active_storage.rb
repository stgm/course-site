require "./lib/svg_previewer"

Rails.application.config.active_storage.previewers << SvgPreviewer
