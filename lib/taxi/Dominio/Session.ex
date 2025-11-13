defmodule Taxi.Session do
  @moduledoc """
  Estructura que modela una sesión de usuario activa en el sistema.

  Campos:
  - username: nombre del usuario autenticado.
  - rol: rol del usuario dentro del sistema ("cliente" o "conductor").
  - nodo: nombre del nodo distribuido donde se originó la sesión.
  - connected_at: marca temporal UTC de inicio de sesión.

  Uso:
  - Simplifica el seguimiento de sesiones en escenarios locales o distribuidos.
  - Adecuada para prácticas académicas sin gestión compleja de tokens.
  """

  defstruct [:username, :rol, :nodo, :connected_at]

  @doc """
  Crea una sesión a partir del nombre de usuario y su rol.
  Asigna automáticamente el nodo actual y la hora UTC de conexión.
  """
  def crear(username, rol) do
    %__MODULE__{
      username: username,
      rol: rol,
      nodo: node(),
      connected_at: DateTime.utc_now()
    }
  end
end
