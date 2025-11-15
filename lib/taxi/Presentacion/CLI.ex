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
    mostrar_banner()
    NodeHelper.info_nodos()

    # Intentar conectar automáticamente a otros nodos
    unless NodeHelper.nodos_conectados?() do
      Util.mostrar_mensaje("\n⚡ Buscando otros nodos en la red...")
      NodeHelper.conectar_nodos()
    end

    Util.mostrar_mensaje("")
    loop(nil, nil)
  end

  # === Banner ===

  defp mostrar_banner do
    Util.mostrar_mensaje("\n╔═══════════════════════════════════════════════════════╗")
    Util.mostrar_mensaje("║                                                       ║")
    Util.mostrar_mensaje("║          🚕  URBANFLEET - Sistema de Taxis  🚕        ║")
    Util.mostrar_mensaje("║                                                       ║")
    Util.mostrar_mensaje("║           Sistema Distribuido de Transporte          ║")
    Util.mostrar_mensaje("║                                                       ║")
    Util.mostrar_mensaje("╚═══════════════════════════════════════════════════════╝")
  end

  # === Loop Principal ===

  defp loop(usuario_actual, rol_actual) do
    mostrar_menu(usuario_actual, rol_actual)

    comando = Util.ingresar("\n🔹 Ingrese comando > ", :texto) |> String.trim() |> String.downcase()
    resultado = procesar_comando(comando, usuario_actual, rol_actual)

    case resultado do
      {:continuar, nuevo_usuario, nuevo_rol} -> loop(nuevo_usuario, nuevo_rol)
      :salir ->
        Util.mostrar_mensaje("\n╔═══════════════════════════════════════╗")
        Util.mostrar_mensaje("║  👋 ¡Gracias por usar UrbanFleet!    ║")
        Util.mostrar_mensaje("║       ¡Hasta pronto!                  ║")
        Util.mostrar_mensaje("╚═══════════════════════════════════════╝\n")
    end
  end

  # === Menús ===

  defp mostrar_menu(nil, nil) do
    Util.mostrar_mensaje("\n┌─────────────────────────────────────────┐")
    Util.mostrar_mensaje("│  📋 MENÚ PRINCIPAL                      │")
    Util.mostrar_mensaje("├─────────────────────────────────────────┤")
    Util.mostrar_mensaje("│  conectar    → Iniciar sesión           │")
    Util.mostrar_mensaje("│  nodos       → Información de nodos     │")
    Util.mostrar_mensaje("│  red         → Diagnóstico de red       │")
    Util.mostrar_mensaje("│  ayuda       → Mostrar ayuda            │")
    Util.mostrar_mensaje("│  salir       → Cerrar programa          │")
    Util.mostrar_mensaje("└─────────────────────────────────────────┘")
  end

  defp mostrar_menu(usuario, :cliente) do
    Util.mostrar_mensaje("\n┌─────────────────────────────────────────┐")
    Util.mostrar_mensaje("│  👤 Usuario: #{String.pad_trailing(usuario, 26)} │")
    Util.mostrar_mensaje("│  🧑 Rol: Cliente                        │")
    Util.mostrar_mensaje("├─────────────────────────────────────────┤")
    Util.mostrar_mensaje("│  📋 COMANDOS DISPONIBLES                │")
    Util.mostrar_mensaje("├─────────────────────────────────────────┤")
    Util.mostrar_mensaje("│  🚗 Viajes:                             │")
    Util.mostrar_mensaje("│    solicitar    → Pedir un viaje        │")
    Util.mostrar_mensaje("├─────────────────────────────────────────┤")
    Util.mostrar_mensaje("│  📊 Estadísticas:                       │")
    Util.mostrar_mensaje("│    puntaje      → Ver mi puntaje        │")
    Util.mostrar_mensaje("│    ranking      → Ver clasificaciones   │")
    Util.mostrar_mensaje("├─────────────────────────────────────────┤")
    Util.mostrar_mensaje("│  🌐 Red:                                │")
    Util.mostrar_mensaje("│    nodos        → Info de nodos         │")
    Util.mostrar_mensaje("│    red          → Diagnóstico de red    │")
    Util.mostrar_mensaje("├─────────────────────────────────────────┤")
    Util.mostrar_mensaje("│  desconectar    → Cerrar sesión         │")
    Util.mostrar_mensaje("│  ayuda          → Mostrar ayuda         │")
    Util.mostrar_mensaje("│  salir          → Cerrar programa       │")
    Util.mostrar_mensaje("└─────────────────────────────────────────┘")
  end

  defp mostrar_menu(usuario, :conductor) do
    Util.mostrar_mensaje("\n┌─────────────────────────────────────────┐")
    Util.mostrar_mensaje("│  👤 Usuario: #{String.pad_trailing(usuario, 26)} │")
    Util.mostrar_mensaje("│  🚗 Rol: Conductor                      │")
    Util.mostrar_mensaje("├─────────────────────────────────────────┤")
    Util.mostrar_mensaje("│  📋 COMANDOS DISPONIBLES                │")
    Util.mostrar_mensaje("├─────────────────────────────────────────┤")
    Util.mostrar_mensaje("│  🚖 Viajes:                             │")
    Util.mostrar_mensaje("│    listar       → Ver viajes disponibles│")
    Util.mostrar_mensaje("│    aceptar      → Aceptar un viaje      │")
    Util.mostrar_mensaje("├─────────────────────────────────────────┤")
    Util.mostrar_mensaje("│  📊 Estadísticas:                       │")
    Util.mostrar_mensaje("│    puntaje      → Ver mi puntaje        │")
    Util.mostrar_mensaje("│    ranking      → Ver clasificaciones   │")
    Util.mostrar_mensaje("├─────────────────────────────────────────┤")
    Util.mostrar_mensaje("│  🌐 Red:                                │")
    Util.mostrar_mensaje("│    nodos        → Info de nodos         │")
    Util.mostrar_mensaje("│    red          → Diagnóstico de red    │")
    Util.mostrar_mensaje("├─────────────────────────────────────────┤")
    Util.mostrar_mensaje("│  desconectar    → Cerrar sesión         │")
    Util.mostrar_mensaje("│  ayuda          → Mostrar ayuda         │")
    Util.mostrar_mensaje("│  salir          → Cerrar programa       │")
    Util.mostrar_mensaje("└─────────────────────────────────────────┘")
  end

  # === Procesador de Comandos ===

  defp procesar_comando(cmd, nil, nil) when cmd in ["conectar", "connect"], do: comando_conectar()
  defp procesar_comando(cmd, usuario, rol) when cmd in ["conectar", "connect"] do
    Util.mostrar_error("❌ Ya estás conectado como #{usuario}")
    {:continuar, usuario, rol}
  end

  defp procesar_comando(cmd, nil, nil) when cmd in ["desconectar", "disconnect"] do
    Util.mostrar_error("❌ No estás conectado")
    {:continuar, nil, nil}
  end
  defp procesar_comando(cmd, usuario, rol) when cmd in ["desconectar", "disconnect"], do: comando_desconectar(usuario)

  # Comando SOLICITAR - Solo para CLIENTES
  defp procesar_comando(cmd, nil, nil) when cmd in ["solicitar", "request_trip", "request"] do
    Util.mostrar_error("❌ Debes conectarte primero")
    {:continuar, nil, nil}
  end
  defp procesar_comando(cmd, usuario, :conductor) when cmd in ["solicitar", "request_trip", "request"] do
    Util.mostrar_error("❌ Solo los clientes pueden solicitar viajes")
    Util.mostrar_mensaje("💡 Como conductor, usa 'listar' y 'aceptar' para tomar viajes")
    {:continuar, usuario, :conductor}
  end
  defp procesar_comando(cmd, usuario, :cliente) when cmd in ["solicitar", "request_trip", "request"], do: comando_solicitar_viaje(usuario)

  # Comando LISTAR - Solo para CONDUCTORES
  defp procesar_comando(cmd, nil, nil) when cmd in ["listar", "list_trips", "list"] do
    Util.mostrar_error("❌ Debes conectarte primero")
    {:continuar, nil, nil}
  end
  defp procesar_comando(cmd, usuario, :cliente) when cmd in ["listar", "list_trips", "list"] do
    Util.mostrar_error("❌ Solo los conductores pueden listar viajes")
    Util.mostrar_mensaje("💡 Como cliente, usa 'solicitar' para pedir un viaje")
    {:continuar, usuario, :cliente}
  end
  defp procesar_comando(cmd, usuario, :conductor) when cmd in ["listar", "list_trips", "list"] do
    comando_listar_viajes()
    {:continuar, usuario, :conductor}
  end

  # Comando ACEPTAR - Solo para CONDUCTORES
  defp procesar_comando(cmd, nil, nil) when cmd in ["aceptar", "accept_trip", "accept"] do
    Util.mostrar_error("❌ Debes conectarte primero")
    {:continuar, nil, nil}
  end
  defp procesar_comando(cmd, usuario, :cliente) when cmd in ["aceptar", "accept_trip", "accept"] do
    Util.mostrar_error("❌ Solo los conductores pueden aceptar viajes")
    Util.mostrar_mensaje("💡 Como cliente, tu viaje será aceptado por un conductor")
    {:continuar, usuario, :cliente}
  end
  defp procesar_comando(cmd, usuario, :conductor) when cmd in ["aceptar", "accept_trip", "accept"], do: comando_aceptar_viaje(usuario)

  # Comando PUNTAJE - Para ambos roles
  defp procesar_comando(cmd, nil, nil) when cmd in ["puntaje", "score"] do
    Util.mostrar_error("❌ Debes conectarte primero")
    {:continuar, nil, nil}
  end
  defp procesar_comando(cmd, usuario, rol) when cmd in ["puntaje", "score"] do
    RankingManager.consultar_puntaje(usuario)
    {:continuar, usuario, rol}
  end

  # Comandos generales
  defp procesar_comando(cmd, usuario, rol) when cmd in ["ranking", "rankings"] do
    comando_ranking()
    {:continuar, usuario, rol}
  end

  defp procesar_comando(cmd, usuario, rol) when cmd in ["nodos", "nodes"] do
    NodeHelper.info_nodos()
    {:continuar, usuario, rol}
  end

  defp procesar_comando(cmd, usuario, rol) when cmd in ["red", "network", "diagnostico"] do
    comando_diagnostico_red()
    {:continuar, usuario, rol}
  end

  defp procesar_comando(cmd, usuario, rol) when cmd in ["ayuda", "help", "?"] do
    mostrar_ayuda(rol)
    {:continuar, usuario, rol}
  end

  defp procesar_comando(cmd, usuario, _rol) when cmd in ["salir", "exit", "quit"] do
    if usuario != nil, do: AuthManager.desconectar(usuario)
    :salir
  end

  defp procesar_comando(_otro, usuario, rol) do
    Util.mostrar_error("❌ Comando no reconocido. Usa 'ayuda' para ver los comandos disponibles")
    {:continuar, usuario, rol}
  end

  # === Implementación de Comandos ===

  defp comando_conectar do
    Util.mostrar_mensaje("\n╔═══════════════════════════════════════╗")
    Util.mostrar_mensaje("║     🔐 INICIAR SESIÓN                 ║")
    Util.mostrar_mensaje("╚═══════════════════════════════════════╝")

    username = Util.ingresar("\n👤 Usuario: ", :texto)
    password = Util.ingresar("🔑 Contraseña: ", :texto)

    Util.mostrar_mensaje("\n┌─────────────────────────┐")
    Util.mostrar_mensaje("│  Seleccione su rol:     │")
    Util.mostrar_mensaje("├─────────────────────────┤")
    Util.mostrar_mensaje("│  1. 🧑 Cliente          │")
    Util.mostrar_mensaje("│  2. 🚗 Conductor        │")
    Util.mostrar_mensaje("└─────────────────────────┘")

    opcion = Util.ingresar("\n🔹 Opción (1 o 2): ", :entero)

    rol = if opcion == 1, do: :cliente, else: :conductor

    case AuthManager.conectar(username, password, rol) do
      {:ok, mensaje} ->
        Util.mostrar_mensaje("\n✅ #{mensaje}")
        rol_texto = if rol == :cliente, do: "cliente", else: "conductor"
        Util.mostrar_mensaje("👤 Conectado como: #{rol_texto}")
        {:continuar, username, rol}
      {:error, mensaje} ->
        Util.mostrar_error("\n❌ #{mensaje}")
        {:continuar, nil, nil}
    end
  end

  defp comando_desconectar(usuario) do
    case AuthManager.desconectar(usuario) do
      {:ok, mensaje} ->
        Util.mostrar_mensaje("\n✅ #{mensaje}")
        {:continuar, nil, nil}
      {:error, mensaje} ->
        Util.mostrar_error("\n❌ #{mensaje}")
        {:continuar, usuario, nil}
    end
  end

  defp comando_solicitar_viaje(usuario) do
    Util.mostrar_mensaje("\n╔═══════════════════════════════════════╗")
    Util.mostrar_mensaje("║     🚕 SOLICITAR VIAJE                ║")
    Util.mostrar_mensaje("╚═══════════════════════════════════════╝")

    {origen, destino} = LocationManager.solicitar_origen_destino()

    case Server.solicitar_viaje(usuario, origen, destino) do
      {:ok, viaje} ->
        Util.mostrar_mensaje("\n┌─────────────────────────────────────┐")
        Util.mostrar_mensaje("│  ✅ ¡Viaje creado exitosamente!     │")
        Util.mostrar_mensaje("├─────────────────────────────────────┤")
        Util.mostrar_mensaje("│  📋 ID: #{String.pad_trailing("#{viaje.id}", 27)} │")
        Util.mostrar_mensaje("│  📍 Origen: #{String.pad_trailing(viaje.origen, 23)} │")
        Util.mostrar_mensaje("│  📍 Destino: #{String.pad_trailing(viaje.destino, 22)} │")
        Util.mostrar_mensaje("│  📊 Estado: #{String.pad_trailing("#{viaje.estado}", 23)} │")
        Util.mostrar_mensaje("└─────────────────────────────────────┘")
        Util.mostrar_mensaje("\n⏱️  El viaje expirará en 40 segundos si no es aceptado.")
      {:error, mensaje} ->
        Util.mostrar_error("\n❌ Error: #{mensaje}")
    end

    {:continuar, usuario, :cliente}
  end

  defp comando_listar_viajes do
    viajes = Server.listar_viajes_disponibles()

    if Enum.empty?(viajes) do
      Util.mostrar_mensaje("\n┌─────────────────────────────────────┐")
      Util.mostrar_mensaje("│  📭 No hay viajes disponibles       │")
      Util.mostrar_mensaje("└─────────────────────────────────────┘")
    else
      Util.mostrar_mensaje("\n╔═══════════════════════════════════════╗")
      Util.mostrar_mensaje("║     🚕 VIAJES DISPONIBLES             ║")
      Util.mostrar_mensaje("╚═══════════════════════════════════════╝")

      Enum.each(viajes, fn viaje ->
        Util.mostrar_mensaje("\n┌─────────────────────────────────────┐")
        Util.mostrar_mensaje("│  🚖 Viaje ##{String.pad_trailing("#{viaje.id}", 24)} │")
        Util.mostrar_mensaje("├─────────────────────────────────────┤")
        Util.mostrar_mensaje("│  👤 Cliente: #{String.pad_trailing(viaje.cliente, 21)} │")
        Util.mostrar_mensaje("│  📍 Origen: #{String.pad_trailing(viaje.origen, 23)} │")
        Util.mostrar_mensaje("│  📍 Destino: #{String.pad_trailing(viaje.destino, 22)} │")
        Util.mostrar_mensaje("└─────────────────────────────────────┘")
      end)
    end
  end

  defp comando_aceptar_viaje(usuario) do
    Util.mostrar_mensaje("\n╔═══════════════════════════════════════╗")
    Util.mostrar_mensaje("║     🚗 ACEPTAR VIAJE                  ║")
    Util.mostrar_mensaje("╚═══════════════════════════════════════╝")

    trip_id = Util.ingresar("\n🔢 ID del viaje: ", :entero)

    case Server.aceptar_viaje(trip_id, usuario) do
      {:ok, viaje} ->
        Util.mostrar_mensaje("\n┌─────────────────────────────────────┐")
        Util.mostrar_mensaje("│  ✅ ¡Viaje aceptado!                │")
        Util.mostrar_mensaje("├─────────────────────────────────────┤")
        Util.mostrar_mensaje("│  📋 ID: #{String.pad_trailing("#{viaje.id}", 27)} │")
        Util.mostrar_mensaje("│  👤 Cliente: #{String.pad_trailing(viaje.cliente, 21)} │")
        Util.mostrar_mensaje("│  📍 Origen: #{String.pad_trailing(viaje.origen, 23)} │")
        Util.mostrar_mensaje("│  📍 Destino: #{String.pad_trailing(viaje.destino, 22)} │")
        Util.mostrar_mensaje("└─────────────────────────────────────┘")
        Util.mostrar_mensaje("\n⏱️  El viaje se completará automáticamente.")
      {:error, mensaje} ->
        Util.mostrar_error("\n❌ Error: #{mensaje}")
    end

    {:continuar, usuario, :conductor}
  end

  defp comando_ranking do
    Util.mostrar_mensaje("\n╔═══════════════════════════════════════╗")
    Util.mostrar_mensaje("║     🏆 RANKINGS DEL SISTEMA           ║")
    Util.mostrar_mensaje("╚═══════════════════════════════════════╝")

    Util.mostrar_mensaje("\n┌─────────────────────────────────────┐")
    Util.mostrar_mensaje("│  1. 🌍 Ranking global               │")
    Util.mostrar_mensaje("│  2. 🚗 Top conductores              │")
    Util.mostrar_mensaje("│  3. 🧑 Top clientes                 │")
    Util.mostrar_mensaje("└─────────────────────────────────────┘")

    case Util.ingresar("\n🔹 Seleccione opción: ", :entero) do
      1 -> RankingManager.mostrar_ranking_global()
      2 -> RankingManager.mostrar_ranking_conductores()
      3 -> RankingManager.mostrar_ranking_clientes()
      _ -> Util.mostrar_error("❌ Opción inválida")
    end
  end

  defp comando_diagnostico_red do
    Util.mostrar_mensaje("\n╔═══════════════════════════════════════════════════════╗")
    Util.mostrar_mensaje("║     🌐 DIAGNÓSTICO Y GESTIÓN DE RED                   ║")
    Util.mostrar_mensaje("╚═══════════════════════════════════════════════════════╝")

    Util.mostrar_mensaje("\n┌───────────────────────────────────────────────────┐")
    Util.mostrar_mensaje("│  1. 📊 Estado actual de la red                    │")
    Util.mostrar_mensaje("│  2. 🔄 Reconectar a todos los nodos               │")
    Util.mostrar_mensaje("│  3. 🔌 Conectar a un nodo específico              │")
    Util.mostrar_mensaje("│  4. 🔍 Probar conectividad con un nodo            │")
    Util.mostrar_mensaje("│  5. 📋 Listar todos los nodos conocidos           │")
    Util.mostrar_mensaje("│  6. ⚠️  Ver problemas de sincronización           │")
    Util.mostrar_mensaje("│  7. 🔧 Reiniciar conexiones                       │")
    Util.mostrar_mensaje("│  0. ⬅️  Volver al menú principal                  │")
    Util.mostrar_mensaje("└───────────────────────────────────────────────────┘")

    case Util.ingresar("\n🔹 Seleccione opción: ", :entero) do
      1 -> diagnostico_estado_red()
      2 -> diagnostico_reconectar_todos()
      3 -> diagnostico_conectar_especifico()
      4 -> diagnostico_probar_nodo()
      5 -> diagnostico_listar_nodos()
      6 -> diagnostico_problemas_sync()
      7 -> diagnostico_reiniciar_conexiones()
      0 -> Util.mostrar_mensaje("\n↩️  Volviendo al menú principal...")
      _ -> Util.mostrar_error("❌ Opción inválida")
    end
  end

  # === Funciones de Diagnóstico de Red ===

  defp diagnostico_estado_red do
    Util.mostrar_mensaje("\n╔═══════════════════════════════════════╗")
    Util.mostrar_mensaje("║     📊 ESTADO DE LA RED               ║")
    Util.mostrar_mensaje("╚═══════════════════════════════════════╝\n")

    nodo_actual = Node.self()
    nodos_conectados = Node.list()
    total_nodos = length(nodos_conectados) + 1

    Util.mostrar_mensaje("🖥️  Nodo actual: #{nodo_actual}")
    Util.mostrar_mensaje("🔗 Nodos conectados: #{length(nodos_conectados)}/#{total_nodos}")

    if Enum.empty?(nodos_conectados) do
      Util.mostrar_mensaje("\n⚠️  No hay otros nodos conectados")
    else
      Util.mostrar_mensaje("\n✅ Nodos activos:")
      Enum.each(nodos_conectados, fn nodo ->
        estado = if Node.ping(nodo) == :pong, do: "🟢 Activo", else: "🔴 Inactivo"
        Util.mostrar_mensaje("   #{estado} - #{nodo}")
      end)
    end

    # Estadísticas adicionales
    Util.mostrar_mensaje("\n📈 Estadísticas:")
    Util.mostrar_mensaje("   • Cookie: #{Node.get_cookie()}")
    Util.mostrar_mensaje("   • Conexiones: #{length(nodos_conectados)}")
  end

  defp diagnostico_reconectar_todos do
    Util.mostrar_mensaje("\n🔄 Intentando reconectar a todos los nodos...")
    NodeHelper.conectar_nodos()

    :timer.sleep(1000)

    nodos_conectados = Node.list()
    if Enum.empty?(nodos_conectados) do
      Util.mostrar_error("\n❌ No se pudo conectar a ningún nodo")
      Util.mostrar_mensaje("\n💡 Sugerencias:")
      Util.mostrar_mensaje("   • Verifica que otros nodos estén ejecutándose")
      Util.mostrar_mensaje("   • Revisa que todos usen el mismo cookie")
      Util.mostrar_mensaje("   • Asegúrate de que no haya firewalls bloqueando")
    else
      Util.mostrar_mensaje("\n✅ Reconexión exitosa a #{length(nodos_conectados)} nodo(s)")
      Enum.each(nodos_conectados, fn nodo ->
        Util.mostrar_mensaje("   🟢 #{nodo}")
      end)
    end
  end

  defp diagnostico_conectar_especifico do
    Util.mostrar_mensaje("\n🔌 Conectar a nodo específico")
    nodo_str = Util.ingresar("\n📝 Ingrese el nombre del nodo (ej: nodo1@localhost): ", :texto)

    nodo = String.to_atom(nodo_str)

    Util.mostrar_mensaje("\n⏳ Intentando conectar a #{nodo}...")

    case Node.connect(nodo) do
      true ->
        Util.mostrar_mensaje("✅ Conexión exitosa con #{nodo}")
      false ->
        Util.mostrar_error("❌ No se pudo conectar con #{nodo}")
        Util.mostrar_mensaje("\n💡 Verifica:")
        Util.mostrar_mensaje("   • El nodo está ejecutándose")
        Util.mostrar_mensaje("   • El nombre es correcto")
        Util.mostrar_mensaje("   • Ambos nodos usan el mismo cookie")
      :ignored ->
        Util.mostrar_mensaje("⚠️  El nodo ya estaba conectado")
    end
  end

  defp diagnostico_probar_nodo do
    nodos = Node.list()

    if Enum.empty?(nodos) do
      Util.mostrar_error("\n❌ No hay nodos conectados para probar")
    else
      Util.mostrar_mensaje("\n🔍 Nodos disponibles para probar:")
      nodos
      |> Enum.with_index(1)
      |> Enum.each(fn {nodo, idx} ->
        Util.mostrar_mensaje("   #{idx}. #{nodo}")
      end)

      idx = Util.ingresar("\n🔹 Seleccione nodo (número): ", :entero)

      if idx > 0 and idx <= length(nodos) do
        nodo = Enum.at(nodos, idx - 1)
        Util.mostrar_mensaje("\n⏳ Probando conectividad con #{nodo}...")

        case Node.ping(nodo) do
          :pong ->
            Util.mostrar_mensaje("✅ Nodo respondiendo correctamente")
            Util.mostrar_mensaje("   🟢 Latencia: OK")
          :pang ->
            Util.mostrar_error("❌ Nodo no responde")
            Util.mostrar_mensaje("   🔴 El nodo puede estar caído o desconectado")
        end
      else
        Util.mostrar_error("❌ Opción inválida")
      end
    end
  end

  defp diagnostico_listar_nodos do
    Util.mostrar_mensaje("\n╔═══════════════════════════════════════╗")
    Util.mostrar_mensaje("║     📋 NODOS CONOCIDOS                ║")
    Util.mostrar_mensaje("╚═══════════════════════════════════════╝\n")

    Util.mostrar_mensaje("🖥️  Nodo actual:")
    Util.mostrar_mensaje("   • #{Node.self()}\n")

    nodos_conectados = Node.list()

    if Enum.empty?(nodos_conectados) do
      Util.mostrar_mensaje("📭 No hay otros nodos conectados")
    else
      Util.mostrar_mensaje("🔗 Nodos conectados:")
      Enum.each(nodos_conectados, fn nodo ->
        ping_result = Node.ping(nodo)
        estado = if ping_result == :pong, do: "🟢", else: "🔴"
        latencia = if ping_result == :pong, do: "OK", else: "TIMEOUT"
        Util.mostrar_mensaje("   #{estado} #{nodo} [#{latencia}]")
      end)
    end
  end

  defp diagnostico_problemas_sync do
    Util.mostrar_mensaje("\n╔═══════════════════════════════════════╗")
    Util.mostrar_mensaje("║     ⚠️  DIAGNÓSTICO DE PROBLEMAS      ║")
    Util.mostrar_mensaje("╚═══════════════════════════════════════╝\n")

    nodos = Node.list()

    if Enum.empty?(nodos) do
      Util.mostrar_mensaje("⚠️  PROBLEMA: No hay nodos conectados")
      Util.mostrar_mensaje("\n🔧 Soluciones sugeridas:")
      Util.mostrar_mensaje("   1. Ejecuta otros nodos con:")
      Util.mostrar_mensaje("      iex --sname nodo1 --cookie secret -S mix")
      Util.mostrar_mensaje("   2. Usa la opción 2 para reconectar")
      Util.mostrar_mensaje("   3. Verifica que el firewall no bloquee conexiones")
    else
      Util.mostrar_mensaje("✅ Conectividad de red: OK")

      problemas = Enum.filter(nodos, fn nodo ->
        Node.ping(nodo) != :pong
      end)

      if Enum.empty?(problemas) do
        Util.mostrar_mensaje("✅ Todos los nodos responden correctamente")
      else
        Util.mostrar_mensaje("\n⚠️  Nodos con problemas:")
        Enum.each(problemas, fn nodo ->
          Util.mostrar_mensaje("   🔴 #{nodo} - No responde")
        end)

        Util.mostrar_mensaje("\n🔧 Soluciones:")
        Util.mostrar_mensaje("   • Reinicia los nodos problemáticos")
        Util.mostrar_mensaje("   • Usa opción 7 para reiniciar conexiones")
      end
    end
  end

  defp diagnostico_reiniciar_conexiones do
    Util.mostrar_mensaje("\n🔧 Reiniciando todas las conexiones...")

    # Desconectar todos
    nodos_actuales = Node.list()
    Enum.each(nodos_actuales, fn nodo ->
      Node.disconnect(nodo)
      Util.mostrar_mensaje("   ❌ Desconectado de #{nodo}")
    end)

    :timer.sleep(500)

    # Reconectar
    Util.mostrar_mensaje("\n🔄 Reconectando...")
    NodeHelper.conectar_nodos()

    :timer.sleep(1000)

    nuevos_nodos = Node.list()

    Util.mostrar_mensaje("\n📊 Resultado:")
    Util.mostrar_mensaje("   • Nodos antes: #{length(nodos_actuales)}")
    Util.mostrar_mensaje("   • Nodos ahora: #{length(nuevos_nodos)}")

    if length(nuevos_nodos) > 0 do
      Util.mostrar_mensaje("\n✅ Conexiones restablecidas:")
      Enum.each(nuevos_nodos, fn nodo ->
        Util.mostrar_mensaje("   🟢 #{nodo}")
      end)
    else
      Util.mostrar_error("\n❌ No se pudieron restablecer las conexiones")
    end
  end

  # === Ayuda ===

  defp mostrar_ayuda(rol) do
    Util.mostrar_mensaje("\n╔═══════════════════════════════════════════════════════╗")
    Util.mostrar_mensaje("║                  📖 AYUDA DEL SISTEMA                  ║")
    Util.mostrar_mensaje("╚═══════════════════════════════════════════════════════╝")

    Util.mostrar_mensaje("\n┌─────────────────────────────────────────────────────┐")
    Util.mostrar_mensaje("│  🔹 COMANDOS GENERALES                              │")
    Util.mostrar_mensaje("├─────────────────────────────────────────────────────┤")
    Util.mostrar_mensaje("│  conectar       Iniciar sesión o registrarse        │")
    Util.mostrar_mensaje("│  desconectar    Cerrar sesión actual                │")
    Util.mostrar_mensaje("│  ayuda          Mostrar esta ayuda                  │")
    Util.mostrar_mensaje("│  salir          Cerrar el programa                  │")
    Util.mostrar_mensaje("└─────────────────────────────────────────────────────┘")

    case rol do
      :cliente ->
        Util.mostrar_mensaje("\n┌─────────────────────────────────────────────────────┐")
        Util.mostrar_mensaje("│  🔹 COMANDOS DE CLIENTE (Tu rol actual)             │")
        Util.mostrar_mensaje("├─────────────────────────────────────────────────────┤")
        Util.mostrar_mensaje("│  solicitar      Solicitar un nuevo viaje            │")
        Util.mostrar_mensaje("│  puntaje        Ver tu puntaje actual               │")
        Util.mostrar_mensaje("└─────────────────────────────────────────────────────┘")

      :conductor ->
        Util.mostrar_mensaje("\n┌─────────────────────────────────────────────────────┐")
        Util.mostrar_mensaje("│  🔹 COMANDOS DE CONDUCTOR (Tu rol actual)           │")
        Util.mostrar_mensaje("├─────────────────────────────────────────────────────┤")
        Util.mostrar_mensaje("│  listar         Ver viajes disponibles              │")
        Util.mostrar_mensaje("│  aceptar        Aceptar un viaje                    │")
        Util.mostrar_mensaje("│  puntaje        Ver tu puntaje actual               │")
        Util.mostrar_mensaje("└─────────────────────────────────────────────────────┘")

      _ ->
        Util.mostrar_mensaje("\n┌─────────────────────────────────────────────────────┐")
        Util.mostrar_mensaje("│  🔹 COMANDOS DE CLIENTE                             │")
        Util.mostrar_mensaje("├─────────────────────────────────────────────────────┤")
        Util.mostrar_mensaje("│  solicitar      Solicitar un nuevo viaje            │")
        Util.mostrar_mensaje("│  puntaje        Ver tu puntaje actual               │")
        Util.mostrar_mensaje("└─────────────────────────────────────────────────────┘")

        Util.mostrar_mensaje("\n┌─────────────────────────────────────────────────────┐")
        Util.mostrar_mensaje("│  🔹 COMANDOS DE CONDUCTOR                           │")
        Util.mostrar_mensaje("├─────────────────────────────────────────────────────┤")
        Util.mostrar_mensaje("│  listar         Ver viajes disponibles              │")
        Util.mostrar_mensaje("│  aceptar        Aceptar un viaje                    │")
        Util.mostrar_mensaje("│  puntaje        Ver tu puntaje actual               │")
    end

    Util.mostrar_mensaje("\n┌─────────────────────────────────────────────────────┐")
    Util.mostrar_mensaje("│  🔹 ESTADÍSTICAS Y RANKINGS                         │")
    Util.mostrar_mensaje("├─────────────────────────────────────────────────────┤")
    Util.mostrar_mensaje("│  ranking        Ver clasificaciones del sistema     │")
    Util.mostrar_mensaje("│                 - Ranking global                    │")
    Util.mostrar_mensaje("│                 - Top conductores                   │")
    Util.mostrar_mensaje("│                 - Top clientes                      │")
    Util.mostrar_mensaje("└─────────────────────────────────────────────────────┘")

    Util.mostrar_mensaje("\n┌─────────────────────────────────────────────────────┐")
    Util.mostrar_mensaje("│  🔹 GESTIÓN DE RED DISTRIBUIDA                      │")
    Util.mostrar_mensaje("├─────────────────────────────────────────────────────┤")
    Util.mostrar_mensaje("│  nodos          Ver información de nodos            │")
    Util.mostrar_mensaje("│  red            Diagnóstico y gestión de red        │")
    Util.mostrar_mensaje("│                 - Estado de la red                  │")
    Util.mostrar_mensaje("│                 - Reconectar nodos                  │")
    Util.mostrar_mensaje("│                 - Conectar nodo específico          │")
    Util.mostrar_mensaje("│                 - Probar conectividad               │")
    Util.mostrar_mensaje("│                 - Diagnóstico de problemas          │")
    Util.mostrar_mensaje("└─────────────────────────────────────────────────────┘")

    Util.mostrar_mensaje("\n┌─────────────────────────────────────────────────────┐")
    Util.mostrar_mensaje("│  💡 TIPS                                            │")
    Util.mostrar_mensaje("├─────────────────────────────────────────────────────┤")
    Util.mostrar_mensaje("│  • Los viajes expiran en 40 segundos                │")
    Util.mostrar_mensaje("│  • Los viajes se completan automáticamente          │")
    Util.mostrar_mensaje("│  • Solo clientes pueden solicitar viajes           │")
    Util.mostrar_mensaje("│  • Solo conductores pueden aceptar viajes          │")
    Util.mostrar_mensaje("│  • El sistema busca nodos automáticamente           │")
    Util.mostrar_mensaje("│  • Usa 'red' si hay problemas de conexión           │")
    Util.mostrar_mensaje("└─────────────────────────────────────────────────────┘")
  end
end
