require 'rake/tasklib'

# In case this file is required directly
require 'docker/compose'

module Docker::Compose
  class RakeTasks < Rake::TaskLib
    attr_accessor :dir, :file, :env

    # Construct Rake wrapper tasks for docker-compose. If a block is given,
    # yield self to the block before defining any tasks so their behavior
    # can be configured by calling namespace=, file= and so forth.
    def initialize
      self.dir = Rake.application.original_dir
      self.file = 'docker-compose.yml'
      self.env = {}
      yield self if block_given?

      @session = Docker::Compose::Session.new(dir:dir, file:file)
      @net_info = Docker::Compose::NetInfo.new

      define
    end

    private def define
      namespace :docker do
        namespace :compose do
          desc 'Print bash exports with IP/ports of running containers'
          task :env do
            commands = []
            mapper = Docker::Compose::Mapper.new(@session,
                                                 @net_info.docker_routable_ip)
            self.env.each_pair do |k, v|
              begin
                commands << format('export %s=%s;', k, mapper.map(v))
              rescue Docker::Compose::Mapper::NoService
                commands << format('unset %s; # service not running', k)
              end
            end
            # Ensure that we export first, so that any unset commands do not
            # unset the variables we are trying to export
            puts commands.sort.join("\n")
          end
        end
      end
    end
  end
end
