defmodule Cogctl.Actions.Bundle.Helpers do
  alias CogApi.Resources.Bundle
  alias CogApi.Resources.BundleVersion

  def enabled?(%{enabled_version: nil}),
    do: false
  def enabled?(_),
    do: true

  def status(%Bundle{}=bundle) do
    if enabled?(bundle) do
      "Enabled"
    else
      "Disabled"
    end
  end
  def status(%BundleVersion{}=bundle_version) do
    if bundle_version.enabled do
      "Enabled"
    else
      "Disabled"
    end
  end

  def field(_label, value) when value in [nil, "", [], :error],
    do: nil
  def field(label, value),
    do: [label, value]

  def value(bundle, path),
    do: get_in(bundle, List.wrap(path))

  def value(bundle, path, fun) do
    case value(bundle, path) do
      nil -> nil
      val -> fun.(val)
    end
  end
end
