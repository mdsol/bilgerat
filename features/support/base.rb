# encoding: utf-8

require 'aruba/cucumber'

After do
  FileUtils.rm_rf  @current_dir if File.directory?(@current_dir)
end
