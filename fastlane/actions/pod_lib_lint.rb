module Fastlane
  module Actions
    class PodLibLintAction < Action
      def self.run(params)
        command = []

        if File.exist?("Gemfile") && params[:use_bundle_exec]
          command << "bundle exec"
        end

        command << "pod lib lint"
        command << "'#{params[:path]}'" if params[:path]

        if params[:verbose]
          command << "--verbose"
        end

        if params[:sources]
          sources = params[:sources].join(",")
          command << "--sources='#{sources}'"
        end

        if params[:allow_warnings]
          command << "--allow-warnings"
        end

        command << "--use-libraries" if params[:use_libraries]
        command << "--fail-fast" if params[:fail_fast]
        command << "--private" if params[:private]
        command << "--quick" if params[:quick]

        result = Actions.sh(command.join(' '))
        UI.success("Pod lib lint Successfully ⬆️ ")
        return result
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Pod lib lint"
      end

      def self.details
        "Test the syntax of your Podfile by linting the pod against the files of its directory"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :path,
                                         description: "podspec path",
                                         is_string: true,
                                         optional: true),
          FastlaneCore::ConfigItem.new(key: :use_bundle_exec,
                                         description: "Use bundle exec when there is a Gemfile presented",
                                         is_string: false,
                                         default_value: true),
          FastlaneCore::ConfigItem.new(key: :verbose,
                                         description: "Allow ouput detail in console",
                                         optional: true,
                                         is_string: false),
          FastlaneCore::ConfigItem.new(key: :allow_warnings,
                                         description: "Allow warnings during pod lint",
                                         optional: true,
                                         is_string: false),
          FastlaneCore::ConfigItem.new(key: :sources,
                                         description: "The sources of repos you want the pod spec to lint with, separated by commas",
                                         optional: true,
                                         is_string: false,
                                         verify_block: proc do |value|
                                           UI.user_error!("Sources must be an array.") unless value.kind_of?(Array)
                                         end),
          FastlaneCore::ConfigItem.new(key: :use_libraries,
                                       description: "Lint uses static libraries to install the spec",
                                       is_string: false,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :fail_fast,
                                       description: "Lint stops on the first failing platform or subspec",
                                       is_string: false,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :private,
                                       description: "Lint skips checks that apply only to public specs",
                                       is_string: false,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :quick,
                                       description: "Lint skips checks that would require to download and build the spec",
                                       is_string: false,
                                       default_value: false)
        ]
      end

      def self.output
      end

      def self.return_value
        nil
      end

      def self.authors
        ["thierryxing"]
      end

      def self.is_supported?(platform)
        true
      end

    end
  end
end