defmodule Taxi.UserManager do
  alias Taxi.{User, UserPersistence}

  def registrar_usuario() do
    nombre = "Ingrese su nombre: "
    |> Util.ingresar(:texto)
    password = "Ingrese su contraseña: "
    |> Util.ingresar(:texto)
    rol = "Ingrese su rol (1-Cliente, 2-Conductor): "
    |> ingresar_rol()
    crear(nombre,password,rol)
    |> UserPersistence.save()
    Util.mostrar_mensaje("Usuario registrado exitosamente.")
  end

  def crear(nombre,password,rol) do
    %User{nombre: nombre,password: password, rol: rol, puntaje: 0}
  end

  def ingresar_rol(mensaje) do
    rol = IO.gets(mensaje) |> String.trim()
    case rol do
      "1" -> :cliente
      "2" -> :conductor
      _ -> ingresar_rol("Ingrese un numero valido(1-Cliente,2-Conductor): ")
    end
  end

  def consultarPuntaje() do
    nombre = IO.gets("Ingrese su nombre: ") |> String.trim()
    case UserPersistence.find_by_name(nombre) do
      nil -> {:error, "Usuario no encontrado"}
      %User{puntaje: puntaje} -> {:ok, puntaje}
    end
  end


end
