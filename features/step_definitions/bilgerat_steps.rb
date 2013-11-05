def debug_file_name
  '/tmp/tempfile.xml'
end

When /^I run bilgerat with: `(.*)`$/ do |cmd|
  step %Q{I run `env DEBUG_BILGERAT=#{debug_file_name} #{cmd}`}
end

When /^I clear hipchat posts$/ do
  File.delete(debug_file_name) if File.exists?(debug_file_name)
end

Before do
  step 'I clear hipchat posts'
end

# For debugging
Then /^I print the hipchat posts$/ do
  puts File.read(debug_file_name)
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