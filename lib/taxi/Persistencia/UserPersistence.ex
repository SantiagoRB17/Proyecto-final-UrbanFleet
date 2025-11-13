defmodule Taxi.UserPersistence do
  @moduledoc """
  Módulo de persistencia enfocado en la gestión de usuarios.
  """

  alias Taxi.{User, Persistence}

  @users_file "data/users.json"

  @doc """
  Lee todos los usuarios desde el archivo JSON.
  Si el archivo no existe, devuelve una lista vacía.
  """
  def load_all do
    Persistence.read_json(@users_file, User)
  end

  @doc """
  Guarda la lista completa de usuarios en el archivo JSON.
  Sobrescribe el contenido anterior para mantener consistencia.
  """
  def save_all(users) do
    Persistence.write_json(@users_file, users)
  end

  @doc """
  Agrega un solo usuario al almacenamiento.
  Lee la lista actual, concatena y vuelve a guardar la lista completa.
  """
  def save(%User{} = user) do
    load_all()
    |> Kernel.++([user])
    |> save_all()
  end

  @doc """
  Busca un usuario por su nombre.
  Retorna el struct `%User{}` si lo encuentra, o `nil` si no existe.
  """
  def find_by_name(nombre) do
    load_all()
    |> Enum.find(&(&1.nombre == nombre))
  end
end
