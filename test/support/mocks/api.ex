defmodule ApiMock do
  use GenServer

  defstruct [:pid, :events]
  alias __MODULE__, as: State

  # API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.fetch!(opts, :name))
  end

  def get_vehicle(name, id), do: GenServer.call(name, {:get_vehicle, id})
  def get_vehicle_with_state(name, id), do: GenServer.call(name, {:get_vehicle_with_state, id})
  def stream(name, vid, receiver), do: GenServer.call(name, {:stream, vid, receiver})

  def sign_in(name, credentials), do: GenServer.call(name, {:sign_in, credentials})

  # Callbacks

  @impl true
  def init(opts) do
    {:ok, %State{pid: Keyword.fetch!(opts, :pid), events: Keyword.get(opts, :events, [])}}
  end

  @impl true
  def handle_call({action, _id}, _from, %State{events: [event | []]} = state)
      when action in [:get_vehicle, :get_vehicle_with_state] do
    {:reply, exec(event), state}
  end

  def handle_call({action, _id}, _from, %State{events: [event | events]} = state)
      when action in [:get_vehicle, :get_vehicle_with_state] do
    {:reply, exec(event), %State{state | events: events}}
  end

  def handle_call({:sign_in, _} = event, _from, %State{pid: pid} = state) do
    send(pid, {ApiMock, event})
    {:reply, :ok, state}
  end

  def handle_call({:stream, _vid, _receiver} = event, _from, %State{pid: pid} = state) do
    send(pid, {ApiMock, event})
    {:reply, {:ok, pid}, state}
  end

  defp exec(event) when is_function(event), do: event.()
  defp exec(event), do: event
end
