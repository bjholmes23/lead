set_default(:phusion_user) { user }

namespace :phusion do

  %w[restart].each do |command|
    desc "#{command} phusion"
    task command, roles: :app do
      run "touch #{release_path}/tmp/restart.txt"
    end
    after "deploy:#{command}", "phusion:#{command}"
  end
  
end
