defmodule Taxi.Persistence do
  @moduledoc """
  Módulo encargado de manejar la lectura y escritura de archivos JSON
  para persistir datos de entidades como usuarios, viajes o resultados.
  """

  def write_json(path, data) do
    # Convertir datos a formato serializable (átomos → strings)
    serializable_data = serialize(data)

    json_content = Jason.encode!(serializable_data, pretty: true)
    File.write!(path, json_content)
  end

  @doc """
  Lee datos desde un archivo JSON y los convierte al struct especificado.
  """
  def read_json(path, struct_module) do
    case File.read(path) do
      {:ok, content} ->
        Jason.decode!(content, keys: :atoms)
        |> Enum.map(&deserialize(&1, struct_module))

      {:error, _} ->
        []
    end
  end


  defp serialize(%_{} = struct) do
    struct
    |> Map.from_struct()
    |> Enum.map(fn {key, value} -> {key, serialize_value(value)} end)
    |> Map.new()
  end

  # Convierte una lista de structs
  defp serialize(list) when is_list(list) do
    Enum.map(list, &serialize/1)
  end

  # Ya es serializable
  defp serialize(other), do: other

  # Convierte átomos a strings (excepto nil, true, false)
  defp serialize_value(atom) when is_atom(atom) and atom not in [nil, true, false] do
    Atom.to_string(atom)
  end

  # Otros valores pasan sin cambio
  defp serialize_value(value), do: value

  # === Funciones Privadas de Deserialización ===

  # Convierte un mapa a struct, manejando conversiones especiales
  defp deserialize(map, struct_module) do
    # Convertir strings a átomos donde sea necesario
    converted_map =
      map
      |> convert_rol_to_atom()
      |> convert_estado_to_atom()

    struct(struct_module, converted_map)
  end

  # Convierte el campo "rol" de string a átomo si existe
  defp convert_rol_to_atom(%{rol: rol} = map) when is_binary(rol) do
    %{map | rol: String.to_atom(rol)}
  end

  defp convert_rol_to_atom(map), do: map

  # Convierte el campo "estado" de string a átomo si existe
  defp convert_estado_to_atom(%{estado: estado} = map) when is_binary(estado) do
    %{map | estado: String.to_atom(estado)}
  end

  defp convert_estado_to_atom(map), do: map
end
