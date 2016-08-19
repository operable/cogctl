timeout = 120000 # 2 minutes per test

File.rm("#{System.cwd!}/cogctl.conf")

ExUnit.start(timeout: timeout)
