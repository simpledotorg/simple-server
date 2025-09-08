module OneOff
  module Opensrp
    # OpenSRP::Exporter
    #
    # Base class which acts as an entry point for the rake task.
    class Exporter
      def self.export config, output
        new(config, output).call!
      end
    end
  end
end
