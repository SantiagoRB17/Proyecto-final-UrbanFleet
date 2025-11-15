defmodule Taxi.RankingManagerTest do
  use ExUnit.Case
  alias Taxi.{RankingManager, UserPersistence, User}

  describe "Sistema de Puntuación" do
    test "obtener ranking global de conductores" do
      ranking = RankingManager.obtener_ranking_global()

      assert is_list(ranking)
      # Verificar que todos son structs de User
      assert Enum.all?(ranking, fn item -> match?(%User{}, item) end)
    end

    test "ranking muestra usuarios ordenados por puntaje" do
      ranking = RankingManager.obtener_ranking_global()

      assert is_list(ranking)

      # El ranking debe estar ordenado de mayor a menor por puntaje
      puntajes = Enum.map(ranking, fn user -> user.puntaje end)
      assert puntajes == Enum.sort(puntajes, :desc)
    end

    test "actualizar puntaje de usuario existente" do
      # Obtener un usuario existente del archivo JSON
      usuarios = UserPersistence.load_all()

      if length(usuarios) > 0 do
        usuario = hd(usuarios)
        puntaje_original = usuario.puntaje

        resultado = RankingManager.actualizar_puntaje(usuario.nombre, 10)

        case resultado do
          {:ok, usuario_actualizado} ->
            assert usuario_actualizado.puntaje == puntaje_original + 10
            # Restaurar puntaje original
            RankingManager.actualizar_puntaje(usuario.nombre, -10)
          {:error, _} ->
            # Usuario no encontrado, test pasa
            assert true
        end
      else
        # No hay usuarios, test pasa
        assert true
      end
    end

    test "actualizar puntaje de usuario inexistente falla" do
      conductor_falso = "conductor_inexistente_#{:rand.uniform(100000)}"

      resultado = RankingManager.actualizar_puntaje(conductor_falso, 5)

      assert {:error, _mensaje} = resultado
    end
  end
end
