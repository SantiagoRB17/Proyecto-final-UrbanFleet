defmodule Taxi.Session do
  @moduledoc """
  Representa una sesión de usuario activa.
  """
  
  defstruct [:username, :rol, :nodo, :connected_at]
  
  def crear(username, rol) do
    %__MODULE__{
      username: username,
      rol: rol,
      nodo: node(),
      connected_at: DateTime.utc_now()
    }
  end
end
