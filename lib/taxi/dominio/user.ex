defmodule Taxi.User do
  @moduledoc """
  Módulo que representa a un usuario en el sistema de taxi.
  """
  @derive {Jason.Encoder, only: [:nombre, :password, :rol, :puntaje]}
  defstruct [
    # Identificador único del usuario
    :nombre,
    # Contraseña simple
    :password,
    # "cliente" o "conductor"
    :rol,
    # Puntaje acumulado
    :puntaje
  ]
end
