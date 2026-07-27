# Downloading all files of a submit as one zip.
#
# Replaces the active_storage-send_zip gem, which read the finished archive back
# into memory and never cleaned up its temp files.
#
module SubmitDownloading

    extend ActiveSupport::Concern

    private

    def send_submit_zip(submit, filename:)
        taken = Set.new
        file = ZipWriter.to_tempfile(basename: "submit") do |zip|
            submit.files.each do |attachment|
                name = ZipWriter.unique_name(attachment.filename.to_s, taken)
                ZipWriter.add_attachment(zip, name, attachment)
            end
        end

        # Rack::TempfileReaper unlinks this once the response has been sent. It
        # normally seeds the key itself, but do not depend on it being in the stack:
        # without the reaper the file is only cleaned up when the Tempfile is
        # collected, which is survivable, whereas a NoMethodError here is not.
        (request.env["rack.tempfiles"] ||= []) << file

        send_file file.path,
            type: "application/zip",
            filename: filename,
            disposition: "attachment"
    end

end
