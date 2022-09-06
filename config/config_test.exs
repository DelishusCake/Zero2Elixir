import Config

config :microservice, 
  port: 0,
  secret_key_base: "+b8hE5ViPsQ/iBmacog3SA=="
config :microservice, Microservice.Repo,
  database: "micro_test",
  username: "postgres",
  password: "password",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
config :microservice, Microservice.Mailer,
  adapter: Bamboo.TestAdapter
