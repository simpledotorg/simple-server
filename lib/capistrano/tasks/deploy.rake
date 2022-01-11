namespace :deploy do
  before :starting, :check_sidekiq_hooks do
    invoke "sidekiq:add_default_hooks"
  end

  desc "Fix Bundler plugin path so it points to the shared path instead of a release path"
  task :fix_bundler_plugin_path do
    on release_roles([:all]) do
      within shared_path do
        # sed -i 's#/home/deploy/apps/simple-server/releases/[0-9]\+/.bundle/#/home/deploy/apps/simple-server/shared/.bundle/#g' plugin/index
        execute "sed", "-i", "'s#/home/deploy/apps/simple-server/releases/[0-9]\+/.bundle/#/home/deploy/apps/simple-server/shared/.bundle/#g'", ".bundle/plugin/index"
      end
    end
  end

  desc "Run tmp:clear on all machines"
  task clear_tmp: [:set_rails_env] do
    on release_roles(:all) do
      within current_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, "tmp:clear"
        end
      end
    end
  end

  desc "Runs any rake task, example: cap deploy:rake task=db:seed"
  task rake: [:set_rails_env] do
    on release_roles([:db]) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, ENV["task"]
        end
      end
    end
  end

  desc "Runs any runner task, example: cap deploy:runner task='RegionBackfill.call'"
  task runner: [:set_rails_env] do
    on release_roles([:app]) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rails, :runner, ENV["task"]
        end
      end
    end
  end

  desc "Print the latest deployed revision SHA"
  task :get_latest_deployed_sha do
    on release_roles([:app]) do
      invoke!("deploy:set_previous_revision")
      puts fetch(:previous_revision)
    end
  end

  desc "Confirm if you really want to execute the task"
  task :confirmation do
    puts <<-WARN

    ===============================================================================

      WARNING: You're about to run tasks on #{fetch(:envs_for_confirmation_step).join("/")} server(s)
      Please confirm that all your intentions are kind and friendly.

      READ THIS IF YOU ARE RUNNING A DEPLOY TASK:

      This will deploy `#{fetch(:branch)}` to `#{fetch(:stage)}`. Ensure that:

      * You are deploying the correct branch
      * You are deploying to the correct environment
      * Your application configs are up-to-date
      * Any necessary database/data migrations have been run

    ===============================================================================

    WARN
    ask :value, "Are you sure you want to continue? (Y)"

    if fetch(:value) != "Y"
      puts "\nDeploy canceled!"
      exit
    end
  end
end
