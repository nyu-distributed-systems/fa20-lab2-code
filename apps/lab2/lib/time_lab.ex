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

end
