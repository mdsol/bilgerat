# encoding: utf-8

# Copied from the cucumber project

Given /^I am in (.*)$/ do |example_dir_relative_path|
  @current_dir = fixtures_dir(example_dir_relative_path)
end

Given /^a standard Cucumber project directory structure$/ do
  @current_dir = `mktemp -d cuc.XXXXXX`.strip
  puts "created cuc dir #{@current_dir}"
  in_current_dir do
    FileUtils.rm_rf 'features' if File.directory?('features')
    FileUtils.mkdir_p 'features/support'
    FileUtils.mkdir 'features/step_definitions'
  end
end

After do
  puts "DEBUG after hook"
 # FileUtils.rm_rf  @current_dir if File.directory?(@current_dir)
  puts "--DEBUG-- should remove current_dir #{ @current_dir } here "
end
