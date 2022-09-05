import Config

config :microservice, 
  port: 8000,
  secret_key_base: "+b8hE5ViPsQ/iBmacog3SA=="
config :microservice, Microservice.Repo,
  database: "micro_dev",
  username: "postgres",
  password: "password",
  hostname: "localhost"
config :microservice, Microservice.Mailer,
  adapter: Bamboo.LocalAdapter
