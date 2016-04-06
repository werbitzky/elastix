defmodule Elastix do
  @moduledoc """
  A module that provides a simple Interface to communicate with an Elastic server via REST.
  """

  @doc false
  def start do
    :application.ensure_all_started(:elastix)
  end

  @doc false
  def config, do: Application.get_env(:elastix, Elastix)
  @doc false
  def config(key), do: Dict.get(config, key)
  @doc false
  def config(key, default), do: Dict.get(config, key, default)
end
