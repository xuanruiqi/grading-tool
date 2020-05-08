require_relative 'reader'
require_relative 'assignment'

def load_assignment(path)
  d = Dir.chdir path do
    filenames = Dir.glob "*.yaml"

    unless filenames.include? "config.yaml" then
      raise 'Error: no config file defining assignment found!'
    end

    assgn = read_config(File.join(path, "config.yaml"))
    filenames.delete "config.yaml"

    submissions = []
    for fn in filenames do
      s = read_submission fn
      assgn.add_submission s
    end

    return assgn
  end
end
