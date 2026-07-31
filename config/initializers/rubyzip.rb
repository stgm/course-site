# rubyzip 3 turns Zip64 on by default, which should be fine, but we
# disable it because we did not have it before, and we don't really need it

Zip.write_zip64_support = false
