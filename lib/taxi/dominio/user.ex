defmodule Taxi.User do
  @moduledoc """
  Estructura de dominio que modela a un usuario dentro del sistema de taxis.

  Campos:
  - nombre: identificador textual único del usuario.
  - password: contraseña en texto plano para autenticación académica simple.
  - rol: rol funcional del usuario, puede ser "cliente" o "conductor".
  - puntaje: acumulado de puntos obtenido por interacciones en el sistema.
  """

  @derive {Jason.Encoder, only: [:nombre, :password, :rol, :puntaje]}
  defstruct [

    :nombre,

    :password,

    :rol,

    :puntaje
  ]
end
