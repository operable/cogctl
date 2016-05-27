use Mix.Config

config :httpotion,
  :default_timeout, 10000 # 10 seconds

config :exvcr, [
  vcr_cassette_library_dir: "test/fixtures/cassettes",
  filter_sensitive_data: [
    # Filter out any potentially sensitive data.
    # These bits aren't really sentitive, but I filtered them out anyway.
    [pattern: "token [^&]+", placeholder: "token xoxb-filtered-token"],
    [pattern: ~s("{\"token\":{\"value\":\"[^"]+"}}), placeholder: ~s("{\"token\":{\"value\":\"filtered-token\"}})]
  ]
]
