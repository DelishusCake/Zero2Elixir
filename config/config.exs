import Config

config :microservice, 
  ecto_repos: [Microservice.Repo]

import_config "config_#{config_env()}.exs"
