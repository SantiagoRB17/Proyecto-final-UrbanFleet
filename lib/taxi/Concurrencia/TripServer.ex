defmodule Taxi.TripServer do
  @moduledoc """
  GenServer que representa un viaje individual dentro del sistema.
  Responsabilidades principales:
  - Mantener el estado del viaje (pendiente, en progreso, completado, expirado).
  - Administrar temporizadores para expirar viajes no aceptados y completar viajes en progreso.
  - Informar mensajes de estado útiles para seguimiento académico y funcional.

  Este módulo modela el ciclo de vida de un viaje usando procesos concurrentes (un proceso por viaje).
  Su terminación es controlada por eventos temporales (expiración o finalización).
  """

  use GenServer
  alias Taxi.{Trip, TripPersistence, RankingManager}

  @timeout 40_000

  # === API Pública ===

  @doc """
  Inicia el proceso GenServer asociado a un viaje.
  Recibe un mapa con los datos iniciales (id, cliente, origen, destino).
  Devuelve {:ok, pid} o {:error, razon}.
  """
  def start_link(datos) do
    GenServer.start_link(__MODULE__, datos)
  end

  @doc """
  Obtiene el estado actual del viaje (struct Trip).
  Se usa para consultar datos como cliente, origen, destino y estado.
  """
  def obtener_estado(pid) do
    GenServer.call(pid, :obtener_estado)
  end

  @doc """
  Intenta aceptar un viaje pendiente por parte de un conductor.
  Si el viaje está disponible cambia a :en_progreso y programa su finalización.
  Devuelve {:ok, viaje_actualizado} o {:error, mensaje}.
  """
  def aceptar(pid, conductor) do
    GenServer.call(pid, {:aceptar, conductor})
  end

  # === Callbacks GenServer ===

  @doc """
  Inicializa el estado interno del viaje.
  Crea la estructura Trip con estado :pendiente y programa un temporizador de expiración.
  """
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

    timer = Process.send_after(self(), :expirar, @timeout)

    "🚕 Viaje #{viaje.id} creado (expira en 40s)"
    |> Util.mostrar_mensaje()

    {:ok, %{viaje: viaje, timer: timer}}
  end

  @doc """
  Maneja la solicitud síncrona para obtener el estado del viaje.
  Responde con la estructura completa Trip.
  """
  def handle_call(:obtener_estado, _from, estado) do
    {:reply, estado.viaje, estado}
  end

  @doc """
  Maneja la aceptación del viaje por un conductor.
  Cancela el temporizador de expiración y programa uno para completar el viaje.
  """
  def handle_call({:aceptar, conductor}, _from, estado) do
    viaje = estado.viaje

    if viaje.estado == :pendiente do
      Process.cancel_timer(estado.timer)

      viaje_actualizado = %{viaje |
        conductor: conductor,
        estado: :en_progreso
      }

      # Tiempo aleatorio entre 20 y 40 segundos
      tiempo_ms = Enum.random(20_000..40_000)
      segundos = div(tiempo_ms, 1000)

      # Mostrar mensaje con duración estimada
      mostrar_mensaje_viaje("ACEPTADO", viaje.id, conductor, nil, segundos)

      nuevo_timer = Process.send_after(self(), :completar, tiempo_ms)

      {:reply, {:ok, viaje_actualizado}, %{estado | viaje: viaje_actualizado, timer: nuevo_timer}}
    else
      {:reply, {:error, "Viaje no disponible"}, estado}
    end
  end

  # === Funciones Auxiliares ===

  @doc """
  Muestra un bloque formateado informando el estado del viaje.
  Tipos posibles: ACEPTADO, EXPIRADO, COMPLETADO.
  Se usa solo internamente para mejorar la salida por consola.
  """
  defp mostrar_mensaje_viaje(tipo, id, conductor, cliente, duracion \\ nil) do
    "\n┌─────────────────────────────────────┐"
    |> Util.mostrar_mensaje()

    case tipo do
      "ACEPTADO" ->
        "│ 🚕 VIAJE #{id} ACEPTADO       │" |> Util.mostrar_mensaje()
        "│ Conductor: #{String.pad_trailing(conductor, 17)} │" |> Util.mostrar_mensaje()
        if duracion do
          "│ Duración estimada: #{String.pad_trailing("#{duracion}s", 13)} │" |> Util.mostrar_mensaje()
        end
      "EXPIRADO" ->
        "│ ⚠️  VIAJE #{id} EXPIRADO       │" |> Util.mostrar_mensaje()
        "│ Cliente: #{String.pad_trailing(cliente, 19)} │" |> Util.mostrar_mensaje()
      "COMPLETADO" ->
        "│ ✅ VIAJE #{id} COMPLETADO     │" |> Util.mostrar_mensaje()
        "│ Cliente: #{String.pad_trailing(cliente, 19)} │" |> Util.mostrar_mensaje()
        "│ Conductor: #{String.pad_trailing(conductor, 17)} │" |> Util.mostrar_mensaje()
    end

    "└─────────────────────────────────────┘"
    |> Util.mostrar_mensaje()
  end

  @doc """
  Maneja el evento de expiración del viaje.
  Cambia estado a :expirado, registra el viaje y penaliza al cliente.
  Termina el proceso después de completar las acciones.
  """
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

  @doc """
  Maneja el evento de finalización de un viaje en progreso.
  Cambia estado a :completado, otorga puntos y registra el viaje.
  Termina el proceso limpiamente.
  """
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
