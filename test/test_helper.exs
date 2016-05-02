timeout = 120000 # 2 minutes per test

# Defines the directory for exvcr fixtures
ExVCR.Config.cassette_library_dir("test/fixtures/cassettes")
# Filter out any potentially sensitive data.
# These bits aren't really sentitive, but I filtered them out anyway.
ExVCR.Config.filter_sensitive_data("token [^&]+", "token xoxb-filtered-token")
ExVCR.Config.filter_sensitive_data(~s("{\"token\":{\"value\":\"[^"]+"}}), ~s("{\"token\":{\"value\":\"filtered-token\"}}))

ExUnit.start(timeout: timeout)
