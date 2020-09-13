defmodule VirtualTimeMessage do
  @moduledoc """
  Structure for virtual clocks.
  """
  defstruct(lamport_clock: 0, vector_clock: %{})

  @doc """
  Return a new `VirtualTimeMessage` with `lamport_clock`
  set to the supplied value.
  """
  @spec new_lamport(non_neg_integer()) :: %VirtualTimeMessage{}
  def new_lamport(lamport_time) do
    %VirtualTimeMessage{lamport_clock: lamport_time}
  end

  @doc """
  Return a new `VirtualTimeMessage` with `vector_clock`
  set to the supplied value.
  """
  @spec new_vector(map()) :: %VirtualTimeMessage{}
  def new_vector(vector_time) do
    %VirtualTimeMessage{vector_clock: vector_time}
  end

  @doc """
  Return a new `VirtualTimeMessage` with `vector_clock` set
  to `vector_time` and Lamport clock set to `lamport_time`.
  """
  @spec new(map(), non_neg_integer()) :: %VirtualTimeMessage{}
  def new(vector_time, lamport_time) do
    %VirtualTimeMessage{vector_clock: vector_time, lamport_clock: lamport_time}
  end
end

defmodule PhysicalTimeMessage do
  import Emulation, only: [now: 0]

  @moduledoc """
  We use the PhysicalTimeMessage module to provide a structure
  used by messages that are used when implementing time synchronization
  with physical clocks. You can add to the struct below, but do not remove
  fields nor change field names.
  """
  defstruct(client_send_time: 0, server_send_time: 0)

  @doc """
  Return a new `PhysicalTimeMessage` that the client can send.
  """
  @spec new_msg() :: %PhysicalTimeMessage{
          client_send_time: pos_integer(),
          server_send_time: non_neg_integer()
        }
  def new_msg do
    %PhysicalTimeMessage{client_send_time: now()}
  end

  @doc """
  Return a new `PhysicalTimeMessage` from the server.
  """
  @spec new_msg(pos_integer()) :: %PhysicalTimeMessage{
          client_send_time: pos_integer(),
          server_send_time: pos_integer()
        }
  def new_msg(client_time) do
    %PhysicalTimeMessage{client_send_time: client_time, server_send_time: now()}
  end
end


defmodule TimeLab do
  @moduledoc """
  Documentation for `TimeLab`.
  """
  import Emulation, only: [spawn: 2, send: 2, timer: 1, now: 0, whoami: 0]

  import Kernel,
    except: [spawn: 3, spawn: 1, spawn_link: 1, spawn_link: 3, send: 2]

  require Fuzzers
  # This allows you to use Elixir's loggers
  # for messages. See
  # https://timber.io/blog/the-ultimate-guide-to-logging-in-elixir/
  # if you are interested in this. Note we currently purge all logs
  # below Info
  require Logger

  @doc """
  Compute and return the updated value of lamport clock.
  `current` is the processes current Lamport clock, while
  `received` is the clock received by the message. Processes
  call `update_lamport_clock/2` each time a message is received,
  and update their internal clock based on the return.
  """
  @spec update_lamport_clock(
          non_neg_integer(),
          non_neg_integer()
        ) :: non_neg_integer()
  def update_lamport_clock(current, received) do
    # TODO: Compute updated value of the lamport clock.
    raise "Not yet implemented"
  end

  @doc """
  Compute and return the updated value of lamport clock.
  `current` is the processes current Lamport clock. Processes
  call `update_lamport_clock/1` before sending each message,
  update their internal clock based on the return and send
  the computed timestamp.
  """
  @spec update_lamport_clock(non_neg_integer()) :: non_neg_integer()
  def update_lamport_clock(current) do
    # TODO: Compute updated value of lamport clock.
    raise "Not yet implemented"
  end

  @spec lamport_ping_server(non_neg_integer()) :: no_return()
  defp lamport_ping_server(clock) do
    receive do
      {who, %VirtualTimeMessage{lamport_clock: received}} ->
        # Update for receive.
        clock = update_lamport_clock(clock, received)
        # Update for send
        clock = update_lamport_clock(clock)
        # Send back response.
        send(who, VirtualTimeMessage.new_lamport(clock))
        lamport_ping_server(clock)

      {who, :current_time} ->
        # Update for receive. This is a message
        # from outside the system, so there is no
        # attached clock.
        clock = update_lamport_clock(clock)
        # Update for send
        clock = update_lamport_clock(clock)
        send(who, clock)
        lamport_ping_server(clock)
    end
  end

  @doc """
  A simple ping server that maintains a Lamport clock.
  """
  @spec lamport_ping_server() :: no_return()
  def lamport_ping_server do
    lamport_ping_server(0)
  end

  @doc """
  Sends a single ping message to `server` with the
  supplied clock. Returns the received clock after updates.
  """
  @spec lamport_ping_client(atom(), non_neg_integer()) :: non_neg_integer()
  def lamport_ping_client(server, clock) do
    # Update for send.
    clock = update_lamport_clock(clock)
    send(server, VirtualTimeMessage.new_lamport(clock))

    receive do
      {^server, %VirtualTimeMessage{lamport_clock: time}} ->
        # Update for receive
        update_lamport_clock(clock, time)

      _ ->
        raise "Unexpected message."
    end
  end

  @spec test_lamport_ping_proc(atom(), pid()) :: boolean()
  defp test_lamport_ping_proc(server, caller) do
    # Start out with a clock of 0, we don't know better.
    clock = lamport_ping_client(server, 0)

    if clock <= 0 do
      raise "The clock should not be 0."
    end

    clock_next = lamport_ping_client(server, clock)

    if clock_next <= clock do
      raise "The clock should move forward."
    end

    send(caller, {:done, clock_next})
  end

  def test_lamport_ping do
    Emulation.init()
    pid = self()
    spawn(:server, &lamport_ping_server/0)
    spawn(:client, fn -> test_lamport_ping_proc(:server, pid) end)

    receive do
      {:done, clock} ->
        clock

      m ->
        raise "Unexpected message #{inspect(m)}"
    end
  after
    Emulation.terminate()
  end

  # Combine a single component in a vector clock.
  @spec combine_component(
          non_neg_integer(),
          non_neg_integer()
        ) :: non_neg_integer()
  defp combine_component(current, received) do
    # TODO Current and received are corresponding components of
    # two vector clocks that need to be combined.
    raise "Not yet implemented"
  end

  @doc """
  Combine vector clocks: this is called whenever a
  message is received, and should return the clock
  from combining the two.
  """
  @spec combine_vector_clocks(map(), map()) :: map()
  def combine_vector_clocks(current, received) do
    # Map.merge just calls the function for any two components that
    # appear in both maps. Anything occuring in only one of the two
    # maps is just copied over. You should convince yourself that this
    # is the correct thing to do here.
    Map.merge(current, received, fn _k, c, r -> combine_component(c, r) end)
  end

  @doc """
  This function is called by the process `proc` whenever an
  event occurs, which for our purposes means whenever a message
  is received or sent.
  """
  @spec update_vector_clock(atom(), map()) :: map()
  def update_vector_clock(proc, clock) do
    # TODO: Update the vector clock. You might find
    # `Map.update!` (https://hexdocs.pm/elixir/Map.html#update!/3)
    # useful.
    raise "Not yet implemented"
  end

  @before :before
  @hafter :after
  @concurrent :concurrent

  # Produce a new vector clock that is a copy of v1,
  # except for any keys (processes) that appear only
  # in v2, which we add with a 0 value. This function
  # is useful in making it so all process IDs do not
  # need to be known a-priori. YOU DO NOT NEED TO DIG
  # INTO THIS CODE, nor understand it.
  @spec make_vectors_equal_length(map(), map()) :: map()
  defp make_vectors_equal_length(v1, v2) do
    v1_add = for {k, _} <- v2, !Map.has_key?(v1, k), do: {k, 0}
    Map.merge(v1, Enum.into(v1_add, %{}))
  end

  # Compare two components of a vector clock c1 and c2.
  # Return @before if a vector of the form [c1] happens before [c2].
  # Return @after if a vector of the form [c2] happens before [c1].
  # Return @concurrent if neither of the above two are true.
  @spec compare_component(
          non_neg_integer(),
          non_neg_integer()
        ) :: :before | :after | :concurrent
  defp compare_component(c1, c2) do
    # TODO: Compare c1 and c2.
    raise "Not yet implemented"
  end

  @doc """
  Compare two vector clocks v1 and v2.
  Returns @before if v1 happened before v2.
  Returns @hafter if v2 happened before v1.
  Returns @concurrent if neither of the above hold.
  """
  @spec compare_vectors(map(), map()) :: :before | :after | :concurrent
  def compare_vectors(v1, v2) do
    # First make the vectors equal length.
    v1 = make_vectors_equal_length(v1, v2)
    v2 = make_vectors_equal_length(v2, v1)
    # `compare_result` is a list of elements from
    # calling `compare_component` on each component of
    # `v1` and `v2`. Given this list you need to figure
    # out whether
    compare_result =
      Map.values(
        Map.merge(v1, v2, fn _k, c1, c2 -> compare_component(c1, c2) end)
      )

    # TODO: You should use the `compare_result` vector
    # to compute a single return value of @before, @hafter
    # or @concurrent here. You might find `Enum.all?`
    # (https://hexdocs.pm/elixir/Enum.html#all?/2) helpful
    # here. For example
    #  `Enum.all?(compare_result, fn x -> x == @concurrent end)`
    # will return true iff all elements in
    # `compare_result` are @concurrent.
    # You might also find `Enum.any?`
    # (https://hexdocs.pm/elixir/Enum.html#any?/2) helpful.
    # For example
    #  `Enum.any?(compare_result, fn x -> x == @concurrent end)`
    # will return true iff at least one element in
    # `compare_result` is @concurrent.

    raise "Not yet implemented"
  end

  @doc """
  A ping server that uses vector clocks.
  """
  @spec vector_ping_server(map()) :: no_return()
  def vector_ping_server(clock) do
    me = whoami()

    receive do
      {sender, %VirtualTimeMessage{vector_clock: received}} ->
        # Event occurred, update.
        clock = update_vector_clock(me, clock)
        # Combine received and current clock.
        clock = combine_vector_clocks(clock, received)
        # About to send, another event.
        clock = update_vector_clock(me, clock)
        send(sender, VirtualTimeMessage.new_vector(clock))
        vector_ping_server(clock)

      {who, :current_time} ->
        # Event occurred, update.
        clock = update_vector_clock(me, clock)
        # Update own clock before sending
        clock = update_vector_clock(me, clock)
        send(who, clock)
        vector_ping_server(clock)
    end
  end

  @doc """
  Send a ping message to a process executing `vector_ping_server`.
  """
  @spec vector_ping_client(atom(), map()) :: map()
  def vector_ping_client(server, time) do
    me = whoami()
    # Update for send event.
    time = update_vector_clock(me, time)
    send(server, VirtualTimeMessage.new_vector(time))

    receive do
      {^server, %VirtualTimeMessage{vector_clock: received}} ->
        time = update_vector_clock(me, time)
        combine_vector_clocks(time, received)

      _ ->
        raise "Unexpected message"
    end
  end

  @spec test_vector_ping_process(atom(), map(), pid()) :: boolean()
  defp test_vector_ping_process(server, time, caller) do
    time_0 = vector_ping_client(server, time)

    if compare_vectors(time_0, time) != @hafter do
      raise "Time or comparison is wrong."
    end

    send(caller, {:done, time_0})
  end

  def test_vector_ping do
    Emulation.init()
    time = %{ping_server: 0, ping_client: 0}
    me = self()

    spawn(
      :ping_server,
      fn -> vector_ping_server(time) end
    )

    spawn(:ping_client, fn ->
      test_vector_ping_process(:ping_server, time, me)
    end)

    receive do
      {:done, time} -> time
      m -> raise "Unexpected message #{inspect(m)}"
    end
  after
    Emulation.terminate()
  end

  # @msg_timeout is ms to wait before deciding a message has been
  # lost by the network. You should not need to use reliable sends
  # and receives (from Lab 1) in this assignment, but need to use
  # timeouts to make sure youd code can make progress despite losses.
  @msg_timeout 10_000

  @spec physical_ping_server() :: no_return()
  defp physical_ping_server do
    receive do
      {sender, %PhysicalTimeMessage{client_send_time: t}} ->
        send(sender, %PhysicalTimeMessage{client_send_time: t})
        physical_ping_server()

      m ->
        raise "Unexpected message #{inspect(m)}"
    end
  end

  @alpha 0.9

  # Keep track of what was previously received and use exponentially
  # weighted moving average to compute the RTT.
  @spec measure_rtt_internal(atom(), number(), number()) :: number()
  defp measure_rtt_internal(physical_ping_server, count, measured) do
    if count > 0 do
      timer(@msg_timeout)
      send(physical_ping_server, PhysicalTimeMessage.new_msg())

      receive do
        {^physical_ping_server, %PhysicalTimeMessage{client_send_time: t}} ->
          time_diff = now() - t

          measure_rtt_internal(
            physical_ping_server,
            count - 1,
            @alpha * measured + (1 - @alpha) * time_diff
          )

        :timer ->
          # No response received.
          measure_rtt_internal(physical_ping_server, count, measured)

        m ->
          raise "Unexpected message #{m}"
      end
    else
      measured
    end
  end

  @doc """
  Measure round-trip time between processes based on `count` pings
  and using `estimate` as an initial estimate for RTT.
  """
  @spec measure_rtt(atom(), number(), number()) :: number()
  def measure_rtt(physical_ping_server, count, estimate) do
    measure_rtt_internal(physical_ping_server, count, estimate)
  end

  @doc """
  A function that can be spawned to execute measure_rtt. The funtion
  returns the measured RTT to `caller` by sending a message.
  """
  @spec rtt_client(atom(), number(), number(), pid()) :: boolean()
  def rtt_client(server, count, estimate, caller) do
    mean_rtt = measure_rtt(server, count, estimate)
    send(caller, {:rtt, mean_rtt})
  end

  @doc """
  Set up a network with 1ms delay (~2ms RTT) and use `physical_ping_server`
  and `rtt_client` to measure the RTT. NOTE: It is very unlikely
  that you will observe RTTs as low as 2ms in when running this
  code. In our experiments we observed ~5ms RTT, and the actual
  value depends on the machine on which this is executed.

  This function passes `estimate` as an initial estimate to
  `measure_rtt`.
  """
  @spec test_measure_rtt(number()) :: number()
  def test_measure_rtt(estimate) do
    Emulation.init()
    pid = self()
    # Don't subject messages to or from this process
    # to fuzzing.
    Emulation.append_fuzzers([Fuzzers.delay(1)])
    Emulation.mark_unfuzzable()
    spawn(:server, &physical_ping_server/0)
    spawn(:client, fn -> rtt_client(:server, 1000, estimate, pid) end)

    receive do
      {:rtt, mean} ->
        mean
    end
  after
    Emulation.terminate()
  end

  @doc """
  Set up a network with 1ms delay (~2ms RTT) and use `physical_ping_server`
  and `rtt_client` to measure the RTT. NOTE: It is very unlikely
  that you will observe RTTs as low as 2ms in when running this
  code. In our experiments we observed ~5ms RTT, and the actual
  value depends on the machine on which this is executed.

  This function assumes a 2ms RTT, which it uses as its initial
  estimate..
  """
  @spec test_measure_rtt() :: number()
  def test_measure_rtt do
    test_measure_rtt(Emulation.millis_to_emu(2))
  end

  @doc """
  Report time.
  """
  @spec time_server() :: no_return()
  def time_server do
    receive do
      {sender, %PhysicalTimeMessage{client_send_time: t}} ->
        send(sender, PhysicalTimeMessage.new_msg(t))
        time_server()

      m ->
        raise "Unexpected message #{inspect(m)}"
    end
  end

  # Interval between time synchronization.
  @sync_interval 200
  @estimated_rtt Emulation.millis_to_emu(2)

  # compute_current_time: takes when a time request was sent,
  # time received from the
  # server, and current RTT to compute and return a tuple of the form
  # `{new_estimated_time, new_estimated_rtt}`.
  # You should use exponentially weighted moving to compute both with @alpha.
  # See `measure_rtt_internal` above for an example.
  @spec compute_current_time(number(), number(), number()) ::
          {number(), number()}
  defp compute_current_time(request_time, server_time, current_rtt) do
    # TODO: Compute and return `{estimated_time, estimated_rtt}`
    raise "Not yet implemented"
  end

  # Pause processing, this hangs the process
  # so it remains alive but isn't doing anything.
  @spec pause() :: no_return
  defp pause() do
    receive do
      _ -> pause()
    end
  end

  # The actual time_sync implementation. You might need
  # to change the spec (e.g., adding more arguments) in
  # order to complete the task. Remember to change both the
  # @spec line, and the actual function signature.
  @spec time_sync(atom(), number(), number()) :: no_return()
  defp time_sync(time_server, wait_until, state) do
    wait_until =
      if wait_until <= 0 do
        send(time_server, PhysicalTimeMessage.new_msg())
        @sync_interval
      else
        wait_until
      end

    t = timer(wait_until)

    receive do
      {^time_server,
       %PhysicalTimeMessage{
         client_send_time: client_time,
         server_send_time: server_time
       }} ->
        time_left =
          case Emulation.cancel_timer(t) do
            false -> 0
            time_left -> time_left
          end

        {new_time, estimate_rtt} =
          compute_current_time(
            client_time,
            server_time,
            state
          )

        Emulation.set_time(new_time)
        time_sync(time_server, time_left, estimate_rtt)

      :timer ->
        time_sync(time_server, 0, state)

      {sender, :pause} ->
        send(sender, :paused)
        pause()
    end
  end

  @doc """
  Synchronize time with `time_server`.
  """
  @spec time_sync(atom()) :: no_return()
  def time_sync(time_server) do
    time_sync(time_server, 0, @estimated_rtt)
  end

  @doc """
  Pause a process running `time_sync` so that we can inspect
  process state.
  """
  @spec pause_and_wait(atom()) :: boolean()
  def pause_and_wait(client) do
    send(client, :pause)

    receive do
      :paused -> true
      m -> raise "Unexpected message #{inspect(m)}"
    end
  end

  @doc """
  Test the time synchronization mechanisms.
  """
  @spec test_time_sync() :: number()
  def test_time_sync() do
    Emulation.init()
    Emulation.append_fuzzers([Fuzzers.delay(10)])
    Emulation.mark_unfuzzable()
    spawn(:time_server, &time_server/0)
    spawn(:time_client, fn -> time_sync(:time_server) end)
    Process.send_after(self(), :timeout, @sync_interval * 10)

    receive do
      :timeout ->
        pause_and_wait(:time_client)
        now = System.monotonic_time()
        server_time = Emulation.translate_time(:time_server, now)
        client_time = Emulation.translate_time(:time_client, now)
        gap = abs(server_time - client_time)
        error = gap / server_time
        {error, gap}

      m ->
        raise "Unexpected message #{inspect(m)}"
    end
  after
    Emulation.terminate()
  end
end
