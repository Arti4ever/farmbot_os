defmodule FarmbotOS.Platform.Target.Network do
  @moduledoc "Manages Network Connections"
  use GenServer, shutdown: 10_000
  require FarmbotCore.Logger
  import FarmbotOS.Platform.Target.Network.Utils
  alias FarmbotOS.Platform.Target.Configurator.{Validator, CaptivePortal}
  alias FarmbotCore.{Asset, Config}

  @default_network_not_found_timer_minutes 20

  def host do
    %{
      type: CaptivePortal,
      wifi: %{
        mode: :host,
        ssid: build_hostap_ssid(),
        key_mgmt: :none,
        scan_ssid: 1,
        ap_scan: 1,
        bgscan: :simple
      },
      ipv4: %{
        method: :static,
        address: "192.168.24.1",
        netmask: "255.255.255.0"
      },
      dnsmasq: %{
        domain: "farmbot",
        server: "192.168.24.1",
        address: "192.168.24.1",
        start: "192.168.24.2",
        end: "192.168.24.10"
      }
    }
  end

  def null do
    %{type: VintageNet.Technology.Null}
  end

  def is_first_connect?() do
    # email = Config.get_config_value(:string, "authorization", "email")
    # password = Config.get_config_value(:string, "authorization", "password")
    # server = Config.get_config_value(:string, "authorization", "server")
    token = Config.get_config_value(:string, "authorization", "token")
    is_nil(token)
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl GenServer
  def init(_args) do
    _ = maybe_hack_tzdata()
    send(self(), :setup)
    # If a secret exists, assume that 
    # farmbot at one point has been connected to the internet
    first_connect? = is_first_connect?()

    if first_connect? do
      :ok = VintageNet.configure("wlan0", null())
      Process.sleep(1500)
      :ok = VintageNet.configure("wlan0", host())
    end

    {:ok, %{network_not_found_timer: nil, first_connect?: first_connect?}}
  end

  @impl GenServer
  def terminate(_, _) do
    :ok = VintageNet.configure("wlan0", null())
    :ok = VintageNet.configure("eth0", null())
  end

  @impl GenServer
  def handle_info(:setup, state) do
    configs = Config.get_all_network_configs()

    case configs do
      [] ->
        Process.send_after(self(), :setup, 5_000)
        {:noreply, state}

      _ ->
        :ok = VintageNet.configure("wlan0", null())
        Process.sleep(1500)
        {:noreply, state, {:continue, configs}}
    end
  end

  def handle_info({VintageNet, ["interface", ifname, "lower_up"], _old, false}, state) do
    FarmbotCore.Logger.error(1, "Interface #{ifname} disconnected from access point")
    state = start_network_not_found_timer(state)
    {:noreply, state}
  end

  def handle_info({VintageNet, ["interface", ifname, "lower_up"], _old, true}, state) do
    FarmbotCore.Logger.error(1, "Interface #{ifname} connected access point")
    state = cancel_network_not_found_timer(state)
    {:noreply, state}
  end

  def handle_info(
        {VintageNet, ["interface", ifname, "connection"], :disconnected, :lan, _},
        state
      ) do
    FarmbotCore.Logger.debug(1, "Interface #{ifname} connected to local area network")
    {:noreply, state}
  end

  def handle_info({VintageNet, ["interface", ifname, "connection"], :lan, :internet, _}, state) do
    FarmbotCore.Logger.debug(1, "Interface #{ifname} connected to internet")
    state = cancel_network_not_found_timer(state)
    {:noreply, %{state | first_connect?: false}}
  end

  def handle_info({VintageNet, ["interface", ifname, "connection"], :internet, ifstate, _}, state) do
    FarmbotCore.Logger.debug(1, "Interface #{ifname} disconnected from the internet: #{ifstate}")

    if state.network_not_found_timer do
      {:noreply, state}
    else
      state = start_network_not_found_timer(state)
      {:noreply, state}
    end
  end

  def handle_info(
        {VintageNet, ["interfaces", "wlan0", "access_points"], _old, _new, _meta},
        state
      ) do
    {:noreply, state}
  end

  def handle_info({VintageNet, property, old, new, _meta}, state) do
    FarmbotCore.Logger.debug(1, """
    Unknown property change: #{inspect(property)}
    old: 

    #{inspect(old, limit: :infinity)}

    new: 

    #{inspect(new, limit: :infinity)}
    """)

    {:noreply, state}
  end

  def handle_info({:network_not_found_timer, minutes}, state) do
    FarmbotCore.Logger.warn(1, """
    Farmbot has been disconnected from the network for 
    #{minutes} minutes. Going
    down for factory reset.

    NOTE: This is temporarily disabled to avoid false positives. 
    If you see this message, and you believe it is incorrect, please
    contact the Farmbot Team with a detailed explanation of what happened
    if possible.
    """)

    # TODO(Connor) factory reset here.

    {:noreply, state}
  end

  @impl GenServer
  def handle_continue([%Config.NetworkInterface{} = config | rest], state) do
    vintage_net_config = to_vintage_net(config)
    FarmbotCore.Logger.busy(3, "#{config.name} starting setup")

    case VintageNet.configure(config.name, vintage_net_config) do
      :ok ->
        state = start_network_not_found_timer(state)
        VintageNet.subscribe(["interface", "#{config.name}"])
        FarmbotCore.Logger.success(3, "#{config.name} setup ok")
        {:noreply, state, {:continue, rest}}

      {:error, reason} ->
        FarmbotCore.Logger.error(3, "#{config.name} setup error: #{inspect(reason)}")
        {:noreply, state, {:continue, rest}}
    end
  end

  def handle_continue([], state) do
    {:noreply, state}
  end

  def to_vintage_net(%Config.NetworkInterface{} = config) do
    %{
      type: Validator,
      network_type: config.type,
      ssid: config.ssid,
      security: config.security,
      psk: config.psk,
      identity: config.identity,
      password: config.password,
      domain: config.domain,
      name_servers: config.name_servers,
      ipv4_method: config.ipv4_method,
      ipv4_address: config.ipv4_address,
      ipv4_gateway: config.ipv4_gateway,
      ipv4_subnet_mask: config.ipv4_subnet_mask,
      regulatory_domain: config.regulatory_domain
    }
  end

  defp cancel_network_not_found_timer(state) do
    old_timer = state.network_not_found_timer
    old_timer && Process.cancel_timer(old_timer)
    %{state | network_not_found_timer: nil}
  end

  defp start_network_not_found_timer(state) do
    state = cancel_network_not_found_timer(state)
    # Stored in minutes
    minutes = network_not_found_timer_minutes(state)
    millis = minutes * 60000
    new_timer = Process.send_after(self(), {:network_not_found_timer, minutes}, millis)

    FarmbotCore.Logger.warn(1, """
    Farmbot will factory reset in #{minutes} minutes 
    if network does not reassosiate
    """)

    %{state | network_not_found_timer: new_timer}
  end

  # if the network has never connected before, make a low
  # thresh so that user won't have to wait 20 minutes to reconfigurate
  # due to bad wifi credentials.
  defp network_not_found_timer_minutes(%{first_connect?: true}), do: 1

  defp network_not_found_timer_minutes(_state) do
    Asset.fbos_config(:network_not_found_timer) || @default_network_not_found_timer_minutes
  end
end
