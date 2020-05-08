# frozen_string_literal: true

require_relative 'reader'
require_relative 'assignment'

def load_assignment(path)
  Dir.chdir path do
    filenames = Dir.glob '*.yaml'

    raise 'Error: no config file defining assignment found!' unless filenames.include? 'config.yaml'

    assgn = read_config(File.join(path, 'config.yaml'))
    filenames.delete 'config.yaml'

    filenames.each do |fn|
      s = read_submission fn
      assgn.add_submission s
    end

    return assgn
  end
end
