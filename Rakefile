require 'bundler'
Bundler::GemHelper.install_tasks

# Bring in Rocco tasks
require 'rocco/tasks'
require 'rake/clean'
Rocco::make 'docs/', 'lib/markdownizer.rb'

desc 'Build markdownizer docs'
task :docs => :rocco
directory 'docs/'

desc 'Build docs and open in browser for the reading'
task :read => :docs do
  sh 'open docs/lib/rocco.html'
end

# Make index.html a copy of markdownizer.html
file 'docs/index.html' => 'docs/lib/markdownizer.html' do |f|
  cp 'docs/lib/markdownizer.html', 'docs/index.html', :preserve => true
end
task :docs => 'docs/index.html'
CLEAN.include 'docs/index.html'

# Alias for docs task
task :doc => :docs

# GITHUB PAGES ===============================================================
#
desc 'Update gh-pages branch'
task :pages => ['docs/.git', :docs] do
  rev = `git rev-parse --short HEAD`.strip
  Dir.chdir 'docs' do
    sh "git add *.html"
    sh "git commit -m 'rebuild pages from #{rev}'" do |ok,res|
      if ok
        verbose { puts "gh-pages updated" }
        sh "git push -q o HEAD:gh-pages"
      end
    end
  end
end
# Update the pages/ directory clone
file 'docs/.git' => ['docs/', '.git/refs/heads/gh-pages'] do |f|
  sh "cd docs && git init -q && git remote add o ../.git" if !File.exist?(f.name)
  sh "cd docs && git fetch -q o && git reset -q --hard o/gh-pages && touch ."
end
CLOBBER.include 'docs/.git'

# desc 'Update gh-pages branch'
# task :pages do
#   file '.git/refs/heads/gh-pages' => 'docs/' do |f|
#       `cd docs && git branch gh-pages --track origin/gh-pages`
#       `git add . && git commit 'updated gh-pages'`
#   end
# end

# TESTS =====================================================================

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

task :default => :spec
task :test => [:spec]
