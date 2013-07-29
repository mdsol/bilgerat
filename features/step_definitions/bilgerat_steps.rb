
def debug_file_name
  '/tmp/tempfile.xml'
end

When /^I run bilgerat with: `(.*)`$/ do |cmd|
  step %Q{I run `env DEBUG_BILGERAT=#{debug_file_name} #{cmd}`}
end

Then /^there should (not )?be a hipchat post matching \/(.*)\/$/ do |should_not, pattern|
  file_text = nil
  File.open(debug_file_name, 'r') do |file|
    file_text = file.read
  end
  re = Regexp.new("<HIPPOST>#{pattern}</HIPPOST>", Regexp::MULTILINE)

  if should_not
    file_text.should_not match(re)
  else
    file_text.should match(re)
  end
end