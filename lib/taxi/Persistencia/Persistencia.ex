defmodule Taxi.Persistence do
  @moduledoc """
  Módulo utilitario para leer y escribir archivos JSON de forma genérica.
  """

  @doc """
  Escribe datos en formato JSON en la ruta indicada.
  Acepta una estructura o una lista de estructuras y realiza las conversiones
  necesarias para que el contenido sea serializable.
  """
  def write_json(path, data) do
    # Convertir datos a formato serializable (átomos → strings)
    serializable_data = serialize(data)

    json_content = Jason.encode!(serializable_data, pretty: true)
    File.write!(path, json_content)
  end

  @doc """
  Lee datos desde un archivo JSON y los convierte al struct especificado.
  Devuelve una lista vacía si el archivo no existe o ocurre un error de lectura.
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

  defp serialize(list) when is_list(list) do
    Enum.map(list, &serialize/1)
  end

  defp serialize(other), do: other

  defp serialize_value(atom) when is_atom(atom) and atom not in [nil, true, false] do
    Atom.to_string(atom)
  end

  defp serialize_value(value), do: value

  # === Funciones Privadas de Deserialización ===

  defp deserialize(map, struct_module) do
    converted_map =
      map
      |> convert_rol_to_atom()
      |> convert_estado_to_atom()

    struct(struct_module, converted_map)
  end

  defp convert_rol_to_atom(%{rol: rol} = map) when is_binary(rol) do
    %{map | rol: String.to_atom(rol)}
  end

  defp convert_rol_to_atom(map), do: map

  defp convert_estado_to_atom(%{estado: estado} = map) when is_binary(estado) do
    %{map | estado: String.to_atom(estado)}
  end

  defp convert_estado_to_atom(map), do: map
end
