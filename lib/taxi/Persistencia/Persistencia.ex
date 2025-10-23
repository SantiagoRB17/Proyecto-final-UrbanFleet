defmodule Taxi.Persistence do
  @moduledoc """
  Módulo encargado de manejar la lectura y escritura de archivos JSON
  para persistir datos de entidades como usuarios, viajes o resultados.
  """

  def write_json(path, data) do
    json_content = Jason.encode!(data, pretty: true)
    File.write!(path, json_content)
  end

  def read_json(path, struct_module) do
    case File.read(path) do
      {:ok, content} ->
        Jason.decode!(content, keys: :atoms)
        |> Enum.map(&struct(struct_module, &1))

      {:error, _} ->
        []
    end
  end
end
