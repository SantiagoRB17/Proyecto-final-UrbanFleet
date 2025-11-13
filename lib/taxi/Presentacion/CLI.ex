defmodule Taxi.CLI do
  @moduledoc """
  Interfaz de línea de comandos para UrbanFleet.

  Este módulo proporciona la interacción principal del usuario con el sistema.
  Permite a clientes solicitar viajes y a conductores aceptarlos.

  ## Funcionalidad Principal
  - Conectar/desconectar usuarios
  - Solicitar viajes (clientes)
  - Listar y aceptar viajes (conductores)
  - Ver puntajes y rankings
  - Gestionar conexiones entre nodos

  ## Uso
      iex> Taxi.CLI.iniciar()

  El sistema presentará un menú interactivo donde el usuario puede
  ejecutar comandos escribiendo el nombre del comando y presionando Enter.
  """

  alias Taxi.{Server, AuthManager, LocationManager, RankingManager, NodeHelper}

  @doc """
  Inicia la interfaz de línea de comandos.

  Muestra el banner del sistema, intenta conectar a otros nodos
  automáticamente y entra en el loop principal de comandos.
  """
  def iniciar do
    Util.mostrar_mensaje("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    Util.mostrar_mensaje("  🚕 URBANFLEET - Terminal de Usuario")
    Util.mostrar_mensaje("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

    NodeHelper.info_nodos()

    # Intentar conectar automáticamente a otros nodos
    unless NodeHelper.nodos_conectados?() do
      Util.mostrar_mensaje("\n⚡ Buscando otros nodos...")
      NodeHelper.conectar_nodos()
    end

    Util.mostrar_mensaje("")

    loop(nil)
  end

  # === Loop Principal ===

  defp loop(usuario_actual) do
    mostrar_menu(usuario_actual)

    comando = Util.ingresar("\n> ", :texto) |> String.trim()
    resultado = procesar_comando(comando, usuario_actual)

    case resultado do
      {:continuar, nuevo_usuario} -> loop(nuevo_usuario)
      :salir -> Util.mostrar_mensaje("\n👋 ¡Hasta pronto!")
    end
  end

  # === Menús ===

  defp mostrar_menu(nil) do
    Util.mostrar_mensaje("\n📋 Comandos disponibles:")
    Util.mostrar_mensaje("  connect    - Conectarse")
    Util.mostrar_mensaje("  nodes      - Ver info de nodos")
    Util.mostrar_mensaje("  help       - Ayuda")
    Util.mostrar_mensaje("  exit       - Salir")
  end

  defp mostrar_menu(usuario) do
    Util.mostrar_mensaje("\n👤 Usuario: #{usuario}")
    Util.mostrar_mensaje("\n📋 Comandos:")
    Util.mostrar_mensaje("  request_trip  - Solicitar viaje")
    Util.mostrar_mensaje("  list_trips    - Listar viajes disponibles")
    Util.mostrar_mensaje("  accept_trip   - Aceptar viaje")
    Util.mostrar_mensaje("  score         - Ver mi puntaje")
    Util.mostrar_mensaje("  ranking       - Ver rankings")
    Util.mostrar_mensaje("  nodes         - Ver info de nodos")
    Util.mostrar_mensaje("  disconnect    - Desconectarse")
    Util.mostrar_mensaje("  exit          - Salir")
  end

  # === Procesador de Comandos ===

  defp procesar_comando("connect", nil), do: comando_conectar()
  defp procesar_comando("connect", usuario) do
    Util.mostrar_error("Ya estás conectado como #{usuario}")
    {:continuar, usuario}
  end

  defp procesar_comando("disconnect", nil) do
    Util.mostrar_error("No estás conectado")
    {:continuar, nil}
  end
  defp procesar_comando("disconnect", usuario), do: comando_desconectar(usuario)

  defp procesar_comando("request_trip", nil) do
    Util.mostrar_error("Debes conectarte primero")
    {:continuar, nil}
  end
  defp procesar_comando("request_trip", usuario), do: comando_solicitar_viaje(usuario)

  defp procesar_comando("list_trips", nil) do
    Util.mostrar_error("Debes conectarte primero")
    {:continuar, nil}
  end
  defp procesar_comando("list_trips", usuario) do
    comando_listar_viajes()
    {:continuar, usuario}
  end

  defp procesar_comando("accept_trip", nil) do
    Util.mostrar_error("Debes conectarte primero")
    {:continuar, nil}
  end
  defp procesar_comando("accept_trip", usuario), do: comando_aceptar_viaje(usuario)

  defp procesar_comando("score", nil) do
    Util.mostrar_error("Debes conectarte primero")
    {:continuar, nil}
  end
  defp procesar_comando("score", usuario) do
    RankingManager.consultar_puntaje(usuario)
    {:continuar, usuario}
  end

  defp procesar_comando("ranking", usuario) do
    comando_ranking()
    {:continuar, usuario}
  end

  defp procesar_comando("help", usuario) do
    mostrar_ayuda()
    {:continuar, usuario}
  end

  defp procesar_comando("nodes", usuario) do
    NodeHelper.info_nodos()
    {:continuar, usuario}
  end

  defp procesar_comando("exit", usuario) do
    if usuario != nil, do: AuthManager.desconectar(usuario)
    :salir
  end

  defp procesar_comando(_otro, usuario) do
    Util.mostrar_error("Comando no reconocido. Usa 'help'")
    {:continuar, usuario}
  end

  # === Implementación de Comandos ===

  defp comando_conectar do
    Util.mostrar_mensaje("\n=== CONECTARSE ===")

    username = Util.ingresar("Usuario: ", :texto)
    password = Util.ingresar("Contraseña: ", :texto)

    Util.mostrar_mensaje("\nRol:")
    Util.mostrar_mensaje("1. Cliente")
    Util.mostrar_mensaje("2. Conductor")
    opcion = Util.ingresar("Seleccione (1 o 2): ", :entero)

    rol = if opcion == 1, do: :cliente, else: :conductor

    case AuthManager.conectar(username, password, rol) do
      {:ok, mensaje} ->
        Util.mostrar_mensaje("✅ #{mensaje}")
        {:continuar, username}
      {:error, mensaje} ->
        Util.mostrar_error("❌ #{mensaje}")
        {:continuar, nil}
    end
  end

  defp comando_desconectar(usuario) do
    case AuthManager.desconectar(usuario) do
      {:ok, mensaje} ->
        Util.mostrar_mensaje("✅ #{mensaje}")
        {:continuar, nil}
      {:error, mensaje} ->
        Util.mostrar_error("❌ #{mensaje}")
        {:continuar, usuario}
    end
  end

  defp comando_solicitar_viaje(usuario) do
    Util.mostrar_mensaje("\n=== SOLICITAR VIAJE ===")

    {origen, destino} = LocationManager.solicitar_origen_destino()

    case Server.solicitar_viaje(usuario, origen, destino) do
      {:ok, viaje} ->
        Util.mostrar_mensaje("\n✅ ¡Viaje creado!")
        Util.mostrar_mensaje("   ID: #{viaje.id}")
        Util.mostrar_mensaje("   Origen: #{viaje.origen}")
        Util.mostrar_mensaje("   Destino: #{viaje.destino}")
        Util.mostrar_mensaje("   Estado: #{viaje.estado}")
        Util.mostrar_mensaje("\n⏱️  Expira en 40 segundos si no es aceptado.")
      {:error, mensaje} ->
        Util.mostrar_error("❌ #{mensaje}")
    end

    {:continuar, usuario}
  end

  defp comando_listar_viajes do
    viajes = Server.listar_viajes_disponibles()

    if Enum.empty?(viajes) do
      Util.mostrar_mensaje("\n📭 No hay viajes disponibles.")
    else
      Util.mostrar_mensaje("\n=== 🚕 VIAJES DISPONIBLES ===")

      Enum.each(viajes, fn viaje ->
        Util.mostrar_mensaje("\n🚖 Viaje ##{viaje.id}")
        Util.mostrar_mensaje("   Cliente: #{viaje.cliente}")
        Util.mostrar_mensaje("   Origen: #{viaje.origen}")
        Util.mostrar_mensaje("   Destino: #{viaje.destino}")
      end)
    end
  end

  defp comando_aceptar_viaje(usuario) do
    Util.mostrar_mensaje("\n=== ACEPTAR VIAJE ===")

    trip_id = Util.ingresar("ID del viaje: ", :entero)

    case Server.aceptar_viaje(trip_id, usuario) do
      {:ok, viaje} ->
        Util.mostrar_mensaje("\n✅ ¡Viaje aceptado!")
        Util.mostrar_mensaje("   ID: #{viaje.id}")
        Util.mostrar_mensaje("   Cliente: #{viaje.cliente}")
        Util.mostrar_mensaje("   Origen: #{viaje.origen}")
        Util.mostrar_mensaje("   Destino: #{viaje.destino}")
        Util.mostrar_mensaje("\n⏱️  Se completará automáticamente.")
      {:error, mensaje} ->
        Util.mostrar_error("❌ #{mensaje}")
    end

    {:continuar, usuario}
  end

  defp comando_ranking do
    Util.mostrar_mensaje("\n=== 🏆 RANKINGS ===")
    Util.mostrar_mensaje("1. Ranking global")
    Util.mostrar_mensaje("2. Top conductores")
    Util.mostrar_mensaje("3. Top clientes")

    case Util.ingresar("Seleccione: ", :entero) do
      1 -> RankingManager.mostrar_ranking_global()
      2 -> RankingManager.mostrar_ranking_conductores()
      3 -> RankingManager.mostrar_ranking_clientes()
      _ -> Util.mostrar_error("Opción inválida")
    end
  end

  defp mostrar_ayuda do
    Util.mostrar_mensaje("\n=== 📖 AYUDA ===")
    Util.mostrar_mensaje("\n🔹 Comandos generales:")
    Util.mostrar_mensaje("  connect     - Conectarse o registrarse")
    Util.mostrar_mensaje("  disconnect  - Desconectarse")
    Util.mostrar_mensaje("  nodes       - Ver información de nodos")
    Util.mostrar_mensaje("  help        - Mostrar esta ayuda")
    Util.mostrar_mensaje("  exit        - Salir del programa")

    Util.mostrar_mensaje("\n🔹 Comandos de cliente:")
    Util.mostrar_mensaje("  request_trip - Solicitar un nuevo viaje")

    Util.mostrar_mensaje("\n🔹 Comandos de conductor:")
    Util.mostrar_mensaje("  list_trips   - Ver viajes disponibles")
    Util.mostrar_mensaje("  accept_trip  - Aceptar un viaje")

    Util.mostrar_mensaje("\n🔹 Otros:")
    Util.mostrar_mensaje("  score    - Ver tu puntaje actual")
    Util.mostrar_mensaje("  ranking  - Ver rankings del sistema")

    Util.mostrar_mensaje("\n🔹 Conexión entre nodos:")
    Util.mostrar_mensaje("  El sistema busca automáticamente otros nodos al iniciar")
    Util.mostrar_mensaje("  Si no se conecta, usa: Taxi.NodeHelper.conectar_nodos()")
  end
end
