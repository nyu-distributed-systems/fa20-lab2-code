defmodule VirtualClockTest do
  use ExUnit.Case
  doctest TimeLab

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  import Emulation, only: [spawn: 2, send: 2]

  test "test_lamport_ping is correct" do
    clock = TimeLab.test_lamport_ping()
    assert clock == 8, "Unexpected Lamport clock value"
  end

  @spec test_lamport_ping_proc(non_neg_integer(), atom(), pid()) :: boolean()
  defp test_lamport_ping_proc(clock, server, caller) do
    clock_0 = TimeLab.lamport_ping_client(server, clock)

    assert clock_0 > clock
    clock_1 = TimeLab.lamport_ping_client(server, clock_0)
    assert clock_1 > clock_0
    assert clock_0 - clock == 4
    assert clock_1 - clock_0 == 4
    send(caller, {:done, clock_1})
  end

  test "Test lamport_ping from different starting point" do
    Emulation.init()
    pid = self()
    spawn(:server, &TimeLab.lamport_ping_server/0)
    spawn(:client, fn -> test_lamport_ping_proc(22, :server, pid) end)

    receive do
      {:done, clock} ->
        clock

      m ->
        raise "Unexpected message #{inspect(m)}"
    end
  after
    Emulation.terminate()
  end

  test "Test lamport clock updates" do
    assert TimeLab.update_lamport_clock(2) == 3
    assert TimeLab.update_lamport_clock(100) == 101
    assert TimeLab.update_lamport_clock(2, 3) == 4
    assert TimeLab.update_lamport_clock(5, 3) == 6
    assert TimeLab.update_lamport_clock(2, 3000) == 3001
  end

  test "test_vector_ping is correct" do
    assert TimeLab.test_vector_ping() == %{ping_server: 2, ping_client: 2}
  end

  test "combine_vector_clocks is correct" do
    assert TimeLab.combine_vector_clocks(
             %{a: 6, b: 2, c: 6},
             %{a: 1, b: 200, c: 6}
           ) == %{a: 6, b: 200, c: 6}

    assert TimeLab.combine_vector_clocks(%{a: 2}, %{b: 3}) ==
             %{a: 2, b: 3}
  end

  test "update_vector_clock is correct" do
    assert TimeLab.update_vector_clock(:a, %{a: 7, b: 22}) ==
             %{a: 8, b: 22}
  end

  test "compare_vectors is correct" do
    assert TimeLab.compare_vectors(%{a: 8, b: 6}, %{a: 7, b: 5}) == :after
    assert TimeLab.compare_vectors(%{a: 7, b: 5}, %{a: 8, b: 6}) == :before
    assert TimeLab.compare_vectors(%{a: 7, b: 5}, %{a: 7, b: 5}) == :concurrent
    assert TimeLab.compare_vectors(%{a: 1, b: 2}, %{a: 2, b: 1}) == :concurrent
    assert TimeLab.compare_vectors(%{a: 22}, %{b: 66}) == :concurrent
  end
end
