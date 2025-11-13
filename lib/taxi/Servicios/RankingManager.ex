defmodule Taxi.RankingManager do
  @moduledoc """
  Servicio de ranking y puntajes de usuarios.
  """

  alias Taxi.{UserPersistence}

  @doc """
  Suma (o resta) puntos al usuario identificado por su nombre.
  Persiste el cambio en el almacenamiento general de usuarios.
  Retorna {:ok, usuario_actualizado} o {:error, "Usuario no encontrado"}.
  """
  def actualizar_puntaje(nombre, puntos) do
    usuarios = UserPersistence.load_all()

    case Enum.find_index(usuarios, &(&1.nombre == nombre)) do
      nil ->
        {:error, "Usuario no encontrado"}

      indice ->
        usuario = Enum.at(usuarios, indice)
        nuevo_puntaje = usuario.puntaje + puntos
        usuario_actualizado = %{usuario | puntaje: nuevo_puntaje}

        usuarios_actualizados = List.replace_at(usuarios, indice, usuario_actualizado)
        UserPersistence.save_all(usuarios_actualizados)

        {:ok, usuario_actualizado}
    end
  end

  @doc """
  Otorga puntos a cliente (+10) y conductor (+15) por un viaje completado.
  Devuelve :ok tras intentar ambas actualizaciones.
  """
  def otorgar_puntos_viaje_completado(cliente, conductor) do
    actualizar_puntaje(cliente, 10)
    actualizar_puntaje(conductor, 15)
    :ok
  end

  @doc """
  Penaliza con -5 puntos al cliente cuando su viaje expira sin ser aceptado.
  Devuelve el resultado de la actualización.
  """
  def penalizar_viaje_expirado(cliente) do
    actualizar_puntaje(cliente, -5)
  end

  @doc """
  Obtiene el ranking global de usuarios (todos los roles) ordenado por puntaje descendente.
  Devuelve una lista de `%User{}`.
  """
  def obtener_ranking_global do
    UserPersistence.load_all()
    |> Enum.sort_by(&(&1.puntaje), :desc)
  end

  @doc """
  Obtiene el ranking de conductores ordenado por puntaje descendente.
  Devuelve una lista de `%User{}` filtrada por rol :conductor.
  """
  def obtener_ranking_conductores do
    UserPersistence.load_all()
    |> Enum.filter(&(&1.rol == :conductor))
    |> Enum.sort_by(&(&1.puntaje), :desc)
  end

  @doc """
  Obtiene el ranking de clientes ordenado por puntaje descendente.
  Devuelve una lista de `%User{}` filtrada por rol :cliente.
  """
  def obtener_ranking_clientes do
    UserPersistence.load_all()
    |> Enum.filter(&(&1.rol == :cliente))
    |> Enum.sort_by(&(&1.puntaje), :desc)
  end

  @doc """
  Toma los primeros n usuarios del ranking global (10 por defecto).
  """
  def obtener_top(n \\ 10) do
    obtener_ranking_global()
    |> Enum.take(n)
  end

  @doc """
  Toma los primeros n usuarios del ranking de conductores (10 por defecto).
  """
  def obtener_top_conductores(n \\ 10) do
    obtener_ranking_conductores()
    |> Enum.take(n)
  end

  @doc """
  Toma los primeros n usuarios del ranking de clientes (10 por defecto).
  """
  def obtener_top_clientes(n \\ 10) do
    obtener_ranking_clientes()
    |> Enum.take(n)
  end

  @doc """
  Muestra por consola el ranking global formateado con posiciones, rol y puntaje.
  Sin retorno significativo (efecto de salida por pantalla).
  """
  def mostrar_ranking_global do
    Util.mostrar_mensaje("\n=== RANKING GLOBAL ===")

    obtener_ranking_global()
    |> Enum.with_index(1)
    |> Enum.each(fn {usuario, posicion} ->
      rol_texto = if usuario.rol == :conductor, do: "Conductor", else: "Cliente"
      Util.mostrar_mensaje("#{posicion}. #{usuario.nombre} (#{rol_texto}) - #{usuario.puntaje} pts")
    end)
  end

  @doc """
  Muestra por consola el ranking de conductores con posiciones y puntaje.
  """
  def mostrar_ranking_conductores do
    Util.mostrar_mensaje("\n=== TOP CONDUCTORES ===")

    obtener_ranking_conductores()
    |> Enum.with_index(1)
    |> Enum.each(fn {conductor, posicion} ->
      Util.mostrar_mensaje("#{posicion}. #{conductor.nombre} - #{conductor.puntaje} pts")
    end)
  end

  @doc """
  Muestra por consola el ranking de clientes con posiciones y puntaje.
  """
  def mostrar_ranking_clientes do
    Util.mostrar_mensaje("\n=== TOP CLIENTES ===")

    obtener_ranking_clientes()
    |> Enum.with_index(1)
    |> Enum.each(fn {cliente, posicion} ->
      Util.mostrar_mensaje("#{posicion}. #{cliente.nombre} - #{cliente.puntaje} pts")
    end)
  end

  @doc """
  Devuelve la posición de un usuario en el ranking global (1-based).
  Retorna {:ok, posicion} o {:error, "Usuario no encontrado en el ranking"}.
  """
  def obtener_posicion(nombre) do
    ranking = obtener_ranking_global()

    case Enum.find_index(ranking, &(&1.nombre == nombre)) do
      nil -> {:error, "Usuario no encontrado en el ranking"}
      indice -> {:ok, indice + 1}
    end
  end

  @doc """
  Consulta y muestra por consola el puntaje y posición de un usuario.
  Si no se encuentra, informa el hecho al usuario.
  """
  def consultar_puntaje(nombre) do
    case UserPersistence.find_by_name(nombre) do
      nil ->
        Util.mostrar_mensaje("Usuario no encontrado")

      usuario ->
        rol_texto = if usuario.rol == :conductor, do: "Conductor", else: "Cliente"
        Util.mostrar_mensaje("\n=== TU PUNTAJE ===")
        Util.mostrar_mensaje("Nombre: #{usuario.nombre}")
        Util.mostrar_mensaje("Rol: #{rol_texto}")
        Util.mostrar_mensaje("Puntaje: #{usuario.puntaje} pts")

        case obtener_posicion(nombre) do
          {:ok, posicion} -> Util.mostrar_mensaje("Posición en ranking: ##{posicion}")
          _ -> :ok
        end
    end
  end
end
