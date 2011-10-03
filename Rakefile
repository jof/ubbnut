root_directory = File.expand_path(File.dirname(__FILE__))
rdoc_directory = File.join(root_directory, 'rdoc')
gemspec_file = File.join(root_directory, '.gemspec')

task :rdoc do
  puts "Removing old rdoc directory at #{rdoc_directory}"
  fork { exec("rm -rf #{rdoc_directory}") }
  Process.wait
  puts "Re-generating rdoc directory."
  fork { exec("rdoc --op #{rdoc_directory} #{root_directory}") }
  Process.wait
end

task :gem do
  puts "Building gem."
  fork { exec("gem build #{gemspec_file}") }
  Process.wait
end
