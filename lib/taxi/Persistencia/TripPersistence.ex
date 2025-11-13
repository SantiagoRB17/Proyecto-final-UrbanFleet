defmodule Taxi.TripPersistence do
  @moduledoc """
  Módulo de persistencia para registrar viajes en un archivo de texto plano.
  """

  @results_file "data/results.log"

  @doc """
  Inicializa el archivo de log si no existe.
  Crea la carpeta `data` y un archivo vacío para comenzar a registrar.
  """
  def inicializar do
    unless File.exists?(@results_file) do
      File.mkdir_p("data")
      File.write!(@results_file, "")
    end
  end

  @doc """
  Registra un viaje en el archivo de log.
  Acepta cualquier estado de viaje y escribe una línea con campos clave.
  """
  def log_trip(trip) do
    inicializar()

    fecha = trip.fecha || Date.utc_today()
    fecha_str = Date.to_string(fecha)

    entrada = format_log_entry(
      fecha_str,
      trip.cliente,
      trip.conductor || "Sin conductor",
      trip.origen,
      trip.destino,
      trip.estado
    )

    File.write!(@results_file, entrada, [:append])
  end

  defp format_log_entry(fecha, cliente, conductor, origen, destino, estado) do
    "#{fecha}; cliente=#{cliente}; conductor=#{conductor}; " <>
    "origen=#{origen}; destino=#{destino}; status=#{estado}\n"
  end
end
