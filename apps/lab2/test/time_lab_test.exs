defmodule TimeLabTest do
  use ExUnit.Case
  doctest TimeLab

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  import Emulation, only: [spawn: 2, send: 2]

  # @tag timeout: 600_000
  # test "Mean RTT measurement is correct" do
  #   rtt_initial = TimeLab.test_measure_rtt()
  #   assert rtt_initial > 0, "A 0 RTT estimare is impossible"

  #   {measured, _} =
  #     1..10
  #     |> Enum.reduce({[], rtt_initial}, fn _, {l, rtt} ->
  #       n_rtt = TimeLab.test_measure_rtt(rtt)
  #       {[n_rtt | l], n_rtt}
  #     end)

  #   measured = Enum.map(measured, &Emulation.emu_to_micros/1)
  #   # Nothing should come back as 0,
  #   assert !Enum.any?(measured, fn x -> x == 0 end), "A 0ms RTT is unlikely."
  #   assert Statistics.stdev(measured) <= 1500, "Too high a standard deviation."
  # end

  @tag timeout: 600_000
  test "Test synchronization" do
    {relative, _} = TimeLab.test_time_sync()
    assert relative <= 0.003, "Relative error should be less than 2 percent."
  end

  @spec time_server() :: no_return()
  defp time_server do
    Emulation.set_time(1_000_000_000)
    TimeLab.time_server()
  end

  @tag timeout: 600_000
  test "Time synchronization works with different start point" do
    Emulation.init()
    Emulation.append_fuzzers([Fuzzers.delay(10)])
    Emulation.mark_unfuzzable()
    spawn(:time_server, &time_server/0)
    spawn(:time_client, fn -> TimeLab.time_sync(:time_server) end)
    Process.send_after(self(), :timeout, 20_000)

    receive do
      :timeout ->
        TimeLab.pause_and_wait(:time_client)
        now = System.monotonic_time()
        server_time = Emulation.translate_time(:time_server, now)
        client_time = Emulation.translate_time(:time_client, now)
        gap = abs(server_time - client_time)
        error = gap / server_time
        assert error <= 0.003, "Relative error should be less than 2%"

      m ->
        raise "Unexpected message #{inspect(m)}"
    end
  after
    Emulation.terminate()
  end

  @tag timeout: 600_000
  test "Time synchronization works with drops" do
    Emulation.init()
    Emulation.append_fuzzers([Fuzzers.drop(0.05), Fuzzers.delay(100)])
    Emulation.mark_unfuzzable()
    spawn(:time_server, &time_server/0)
    spawn(:time_client, fn -> TimeLab.time_sync(:time_server) end)
    Process.send_after(self(), :timeout, 20_000)

    receive do
      :timeout ->
        TimeLab.pause_and_wait(:time_client)
        now = System.monotonic_time()
        server_time = Emulation.translate_time(:time_server, now)
        client_time = Emulation.translate_time(:time_client, now)
        gap = abs(server_time - client_time)
        error = gap / server_time
        IO.puts("#{error} #{gap}")
        assert error <= 0.003, "Relative error should be less than 2%"

      m ->
        raise "Unexpected message #{inspect(m)}"
    end
  after
    Emulation.terminate()
  end
end
