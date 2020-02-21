# frozen_string_literal: true

require 'pathname'

module Libs
  class RailsTemplate < Thor::Group
    include Thor::Actions
    include Rails::Generators::Actions

    attr_accessor :options

    def self.source_root
      File.join(__dir__, '../templates')
    end

    def create_initial_commit
      run 'bundle install'
      run 'bundle binstubs bundler'
      add_commit 'Init'
    end

    def install_rspec(version)
      insert_into_file 'Gemfile',
                       "  gem 'rspec-rails', '~> #{version}'\n",
                       after: "group :development, :test do\n"
      run 'bundle install'
      run 'rails generate rspec:install'
      add_commit 'Add rspec'
    end

    def add_test_gem_group
      return unless api?

      # remove existing group test created by rails
      # gsub_file('Gemfile', /^(group :test)[\s\S]*?[\n\r]end\n/, '')
      insert_into_file 'Gemfile', before: "group :development, :test do\n" do
        <<~RUBY
          group :test do
          end
        RUBY
      end
    end

    def install_capybara(version)
      if api?
        insert_into_file 'Gemfile',
                         "  gem 'capybara', '~> #{version}'\n",
                         after: "group :test do\n"
      end

      run 'bundle install'
      copy_file 'spec/support/capybara.rb'
      insert_into_file 'spec/rails_helper.rb',
                       "require 'support/capybara'\n",
                       after: "require 'spec_helper'\n"
      add_commit 'Add capybara'
    end

    def install_factory_bot(version)
      insert_into_file 'Gemfile',
                       "  gem 'factory_bot_rails', '~> #{version}'\n",
                       after: "group :test do\n"
      run 'bundle install'
      copy_file 'spec/support/factory_bot.rb'
      insert_into_file 'spec/rails_helper.rb',
                       "require 'support/factory_bot'\n",
                       after: "require 'spec_helper'\n"
      add_commit 'Add factory_bot_rails'
    end

    def install_shoulda_matchers(version)
      insert_into_file 'Gemfile',
                       "  gem 'shoulda-matchers', '~> #{version}'\n",
                       after: "group :test do\n"
      run 'bundle install'
      copy_file 'spec/support/shoulda_matchers.rb'
      insert_into_file 'spec/rails_helper.rb',
                       "require 'support/shoulda_matchers'\n",
                       after: "require 'spec_helper'\n"
      add_commit 'Add shoulda-matchers'
    end

    def install_rubocop
      copy_file '.editorconfig'
      copy_file '.rubocop.yml'

      # remove Gemfile comments
      gsub_file('Gemfile', /(^#|(^\s+#))(?! gem).*\n/, '')

      insert_into_file 'Gemfile', after: "group :development, :test do\n" do
        <<~RUBY
          gem 'rubocop', require: false
          gem 'rubocop-performance', require: false
          gem 'rubocop-rails', require: false
        RUBY
      end

      run 'bundle install'
      run 'bundle exec rubocop --auto-correct --disable-uncorrectable'
      add_commit 'Add rubocop and editorconfig'
    end

    private

    def api?
      options[:api]
    end

    def add_commit(message)
      run 'git add -A'
      run "git commit -m '#{message}'"
    end
  end
end
