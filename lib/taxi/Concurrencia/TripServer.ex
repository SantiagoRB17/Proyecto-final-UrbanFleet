defmodule Taxi.TripServer do
  @moduledoc """
  GenServer que representa un viaje individual.
  Maneja temporizador y estados del viaje.
  """

  use GenServer
  alias Taxi.{Trip, TripPersistence, RankingManager}

  @timeout 40_000 

  # === API Pública ===

  def start_link(datos) do
    GenServer.start_link(__MODULE__, datos)
  end

  def obtener_estado(pid) do
    GenServer.call(pid, :obtener_estado)
  end

  def aceptar(pid, conductor) do
    GenServer.call(pid, {:aceptar, conductor})
  end

  # === Callbacks GenServer ===

  def init(datos) do
    viaje = %Trip{
      id: datos.id,
      fecha: Date.utc_today(),
      cliente: datos.cliente,
      conductor: nil,
      origen: datos.origen,
      destino: datos.destino,
      estado: :pendiente
    }

    # Iniciar temporizador de expiración
    timer = Process.send_after(self(), :expirar, @timeout)

    "🚕 Viaje #{viaje.id} creado (expira en 40s)"
    |> Util.mostrar_mensaje()

    {:ok, %{viaje: viaje, timer: timer}}
  end

  def handle_call(:obtener_estado, _from, estado) do
    {:reply, estado.viaje, estado}
  end

  def handle_call({:aceptar, conductor}, _from, estado) do
    viaje = estado.viaje

    if viaje.estado == :pendiente do
      # Cancelar temporizador de expiración
      Process.cancel_timer(estado.timer)

      # Actualizar viaje
      viaje_actualizado = %{viaje |
        conductor: conductor,
        estado: :en_progreso
      }

      # Mostrar mensaje de aceptación
      mostrar_mensaje_viaje("ACEPTADO", viaje.id, conductor, nil)

      # Nuevo temporizador para completar (40 segundos)
      nuevo_timer = Process.send_after(self(), :completar, @timeout)

      {:reply, {:ok, viaje_actualizado}, %{estado | viaje: viaje_actualizado, timer: nuevo_timer}}
    else
      {:reply, {:error, "Viaje no disponible"}, estado}
    end
  end

  # === Funciones Auxiliares ===

  defp mostrar_mensaje_viaje(tipo, id, conductor, cliente) do
    "\n┌─────────────────────────────────────┐"
    |> Util.mostrar_mensaje()

    case tipo do
      "ACEPTADO" ->
        "│ 🚕 VIAJE #{id} ACEPTADO       │"
        |> Util.mostrar_mensaje()
        "│ Conductor: #{String.pad_trailing(conductor, 17)} │"
        |> Util.mostrar_mensaje()

      "EXPIRADO" ->
        "│ ⚠️  VIAJE #{id} EXPIRADO       │"
        |> Util.mostrar_mensaje()
        "│ Cliente: #{String.pad_trailing(cliente, 19)} │"
        |> Util.mostrar_mensaje()

      "COMPLETADO" ->
        "│ ✅ VIAJE #{id} COMPLETADO     │"
        |> Util.mostrar_mensaje()
        "│ Cliente: #{String.pad_trailing(cliente, 19)} │"
        |> Util.mostrar_mensaje()
        "│ Conductor: #{String.pad_trailing(conductor, 17)} │"
        |> Util.mostrar_mensaje()
    end

    "└─────────────────────────────────────┘"
    |> Util.mostrar_mensaje()
  end

  # Manejo de expiración
  def handle_info(:expirar, estado) do
    viaje = estado.viaje

    if viaje.estado == :pendiente do
      # Mostrar mensaje
      mostrar_mensaje_viaje("EXPIRADO", viaje.id, nil, viaje.cliente)

      viaje_expirado = %{viaje | estado: :expirado}

      # Operaciones con manejo de errores
      try do
        RankingManager.penalizar_viaje_expirado(viaje.cliente)
        TripPersistence.log_trip(viaje_expirado)
        GenServer.cast(Taxi.Server, {:limpiar_viaje, viaje.id})
      rescue
        error ->
          "Error al procesar expiración: #{inspect(error)}"
          |> Util.mostrar_error()
      end

      # Terminar proceso limpiamente
      {:stop, :normal, %{estado | viaje: viaje_expirado}}
    else
      {:noreply, estado}
    end
  end

  # Manejo de completado
  def handle_info(:completar, estado) do
    viaje = estado.viaje

    if viaje.estado == :en_progreso do
      # Mostrar mensaje
      mostrar_mensaje_viaje("COMPLETADO", viaje.id, viaje.conductor, viaje.cliente)

      viaje_completado = %{viaje | estado: :completado}

      # Operaciones con manejo de errores
      try do
        RankingManager.otorgar_puntos_viaje_completado(viaje.cliente, viaje.conductor)
        TripPersistence.log_trip(viaje_completado)
        GenServer.cast(Taxi.Server, {:limpiar_viaje, viaje.id})
      rescue
        error ->
          "Error al procesar completado: #{inspect(error)}"
          |> Util.mostrar_error()
      end

      # Terminar proceso limpiamente
      {:stop, :normal, %{estado | viaje: viaje_completado}}
    else
      {:noreply, estado}
    end
  end
end
