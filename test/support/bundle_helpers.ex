defmodule Support.BundleHelpers do
  alias Support.CliHelpers

  @template_dir Path.join(CliHelpers.scratch_dir, "templates")

  def cleanup do
    # Get the list of bundles
    # This is highly dependant on the output of 'cogctl bundles'
    bundle_names = CliHelpers.run("cogctl bundle")
    |> String.split("\n")
    |> tl
    |> Enum.reject(&(Regex.match?(~r(operable|site), &1)))
    |> Enum.map(&String.split(&1, ~r(\s+)))
    |> Enum.reject(&(length(&1) <= 1))
    |> Enum.map(&hd/1)

    Enum.each(bundle_names, &CliHelpers.run("cogctl bundle disable #{&1}"))
    Enum.each(bundle_names, &CliHelpers.run("cogctl bundle uninstall #{&1} --all"))
  end

  @doc """
  Creates a simple bundle config.
  """
  @spec create_config_file(String.t) :: Path.t
  def create_config_file(name) do
    File.mkdir_p!(CliHelpers.scratch_dir)
    config_path = Path.join(CliHelpers.scratch_dir, "#{name}.yaml")

    config = """
    ---
    name: #{name}
    version: 0.0.1
    cog_bundle_version: 3
    commands:
      bar:
        executable: /bin/foobar
        rules:
        - "allow"
    """

    File.write!(config_path, config)
    config_path
  end

  @doc """
  Creates a deprecated config file
  """
  @spec create_old_config_file(String.t) :: Path.t
  def create_old_config_file(name) do
    File.mkdir_p!(CliHelpers.scratch_dir)
    config_path = Path.join(CliHelpers.scratch_dir, "#{name}.yaml")

    config = """
    ---
    name: #{name}
    version: 0.0.1
    cog_bundle_version: 2
    commands:
      bar:
        executable: /bin/foobar
        enforcing: false
    """

    File.write!(config_path, config)
    config_path
  end

  @doc """
  Creates a templates directory structure with two templates, foo and bar, for
  slack and hipchat.
  """
  @spec create_templates() :: Path.t
  def create_templates do
    Enum.each(["slack", "hipchat"], fn(adapter) ->
      template_dir = Path.join(@template_dir, adapter)
      File.mkdir_p!(template_dir)

      Enum.each(["foo", "bar"], &File.write!(Path.join(template_dir, "#{&1}.mustache"), "{{#{&1}}}"))
    end)
    @template_dir
  end

  @doc """
  Creates a bundle
  """
  @spec create_bundle(String.t) :: String.t
  def create_bundle(name) do
    config_path = create_config_file(name)
    Support.CliHelpers.run("cogctl bundle install #{config_path}")
    name
  end

end