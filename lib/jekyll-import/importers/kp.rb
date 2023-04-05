module JekyllImport
  module Importers
    class Kp < Importer
      POSTS_QUERY = "SELECT title, \
                       post, \
                       param \
                     FROM blog_posts \
                     WHERE published = 't'"

      ACHIEVEMENTS_QUERY = "SELECT rank, \
                              heading, \
                              description \
                            FROM achievements"

      TESTIMONIALS_QUERY = "SELECT rank, \
                              provider_name, \
                              provider_position, \
                              recommendation_year, \
                              recommendation
                            FROM testimonials"
      def self.require_deps
        JekyllImport.require_with_fallback(%w(
          safe_yaml
          sequel
          pg
        ))
      end

      def self.specify_options(c)
        c.option "dbname",   "--dbname DB",   "Database name (default: '')"
        c.option "user",     "--user USER",   "Database user name (default: '')"
        c.option "password", "--password PW", "Database user's password (default: '')"
        c.option "host",     "--host HOST",   "Database host name (default: 'localhost')"
      end

      def self.process(opts)
        options = {
          dbname: opts.fetch("dbname", "kpdotcom_development"),
          user: opts.fetch("user", ""),
          password: opts.fetch("password", ""),
          host: opts.fetch("host", "")
        }

        db = Sequel.postgres(
          options[:dbname],
          db_connect_options(options)
        )

        process_posts(db)
        process_achievements(db)
        process_testimonials(db)
      end

      def self.db_connect_options(opts)
        {
          dbname: opts[:dbname],
          user: opts[:user],
          password: opts[:password],
          host: opts[:host]
        }
      end

      def self.process_posts(db)
        FileUtils.mkdir_p("_posts")

        db[POSTS_QUERY].each do |post|
          title = post[:title]
          content = post[:post]
          param = post[:param]
          year = param.split('-').first.to_i
          month = param.split('-')[1].to_i
          day = param.split('-')[2].to_i
          puts "Processing post with title #{title} ..."

          File.open("_posts/#{param}.textile", "w") do |f|
            f.puts '---'
            f.puts 'layout: post'
            f.puts "title: #{title}"
            f.puts "date: #{Date.new(year, month, day)}"
            f.puts "permalink: /blog/archives/#{param}"
            f.puts '---'
            f.puts content
          end
        end
      end

      def self.process_achievements(db)
        FileUtils.mkdir_p("_achievements")

        db[ACHIEVEMENTS_QUERY].each do |achievement|
          rank = achievement[:rank]
          heading = achievement[:heading]
          description = achievement[:description]
          if achievement[:heading] == 'Earlier Positions (1983 - 1997)'
            role = 'Earlier Positions'
            org = ''
          elsif achievement[:heading] == 'Qualifications'
            role = 'Qualifications'
            org = ''
          else
            role = heading.split(',').first.strip
            org = heading.split(',').last.split(' (').first
          end
          filename = "#{rank.to_s.rjust(3, '0')}-#{role.downcase.gsub(' ', '-')}#{org.downcase.gsub(' ', '-')}"
          puts "Processing achievement with heading #{heading} ..."

          File.open("_achievements/#{filename}.textile", "w") do |f|
            f.puts '---'
            f.puts 'layout: none'
            f.puts "heading: #{heading}"
            f.puts '---'
            f.puts description
          end
        end
      end

      def self.process_testimonials(db)
        FileUtils.mkdir_p("_testimonials")

        db[TESTIMONIALS_QUERY].each do |testimonial|
          rank = testimonial[:rank]
          name = testimonial[:provider_name]
          position = testimonial[:provider_position]
          year = testimonial[:recommendation_year]
          recommendation = testimonial[:recommendation]
          filename = "#{rank.to_s.rjust(3, '0')}-#{name.downcase.gsub(' ', '-')}-#{year}"
          puts "Processing testimonial with filename #{filename} ..."

          File.open("_testimonials/#{filename}.textile", "w") do |f|
            f.puts '---'
            f.puts 'layout: none'
            f.puts "provider: #{name}, #{position} (#{year})"
            f.puts '---'
            f.puts recommendation
          end
        end
      end
    end
  end
end
