defmodule Taxi.TripPersistence do

  @results_file "data/results.log"


  def log_completed_trip(trip) do
    fecha = Date.utc_today() |> Date.to_string()

    entrada = format_log_entry(
      fecha,
      trip.client,
      trip.driver,
      trip.origin,
      trip.destination,
      trip.status
    )

    File.write!(@results_file, entrada, [:append])
  end


  defp format_log_entry(fecha, cliente, conductor, origen, destino, estado) do
    "#{fecha}; cliente=#{cliente}; conductor=#{conductor}; " <>
    "origen=#{origen}; destino=#{destino}; status=#{estado}\n"
  end
end
