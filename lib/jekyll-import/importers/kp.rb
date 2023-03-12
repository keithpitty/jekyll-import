module JekyllImport
  module Importers
    class Kp < Importer
      QUERY = "SELECT title, \
                      post, \
                      published_at, \
                      param \
               FROM blog_posts \
               WHERE published = 't'"

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

        FileUtils.mkdir_p("_posts")

        db = Sequel.postgres(
          options[:dbname],
          db_connect_options(options)
        )

        db[QUERY].each do |post|
          title = post[:title]
          content = post[:post]
          published_at = post[:published_at]
          param = post[:param]
          puts "Processing post with title #{title} ..."

          # To be continued
        end
      end

      def self.db_connect_options(opts)
        {
          dbname: opts[:dbname],
          user: opts[:user],
          password: opts[:password],
          host: opts[:host]
        }
      end
    end
  end
end
