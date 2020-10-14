module SimpleServerExtensions
  def env
    SIMPLE_SERVER_ENV
  end

  def git_ref(short: false)
    @git_ref ||= if Rails.root.join("REVISION").exist?
      Rails.root.join("REVISION").read
    else
      `git rev-parse HEAD`.chomp
    end.freeze
    short ? @git_ref[0..6] : @git_ref
  end
end

SimpleServer.extend SimpleServerExtensions
