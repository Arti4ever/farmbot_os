defmodule FarmbotCore.GlobalTracker do
  defmodule Resource do
    defstruct [:name, :status, :pending]
  end
  defmodule Service do
    defstruct [:name, :status, :pending]
  end
  defmodule Event do
    defstruct [:name, :status, :pending]
  end

  @initial_state [
    %Resource{name: :device, status: :pending, waiting: [:http]},
    %Resource{name: :fbos_config, status: :pending, waiting: [:http]},
    %Resource{name: :firmware_config, status: :pending, waiting: [:http]},
    %Resource{name: :farmware_env, status: :pending, waiting: [:http]},
    %Resource{name: :first_party_farmware, status: :pending, waiting: [:http]},
    %Resource{name: :farmware_installation, status: :pending, waiting: [:http]},
    %Resource{name: :peripheral, status: :pending, waiting: [:http, :firmware]},
    %Resource{name: :point, status: :pending, waiting: [:http]},
    %Resource{name: :sensor, status: :pending, waiting: [:http]},
    %Resource{name: :tool, status: :pending, waiting: [:http, :point]},
    %Resource{name: :sequence, status: :pending, waiting: [
      :http, :firmware, :point, :tool, :point_group, :sensor, :peripheral,
    ]},
    %Resource{name: :point_group, status: :pending, waiting: [:http, :point]},
    %Resource{name: :regimen, status: :pending, waiting: [:http, :sequence]},
    %Resource{name: :pin_binding, status: :pending, waiting: [:http, :sequence]},
    %Resource{name: :farm_even, status: :pending, waiting: [:http, :sequence, :regimen]},

    %Service{name: :network, status: :pending, waiting: []},
    %Service{name: :ntp, status: :pending, waiting: [:network]},
    %Service{name: :http, status: :pending, waiting: [:network, :ntp]},
    %Service{name: :amqp, status: :pending, waiting: [:network, :ntp, :http,
      :device,
      :fbos_config,
      :firmware_config,
      :farmware_env,
      :first_party_farmware,
      :farmware_installation,
      :peripheral,
      :point,
      :sensor,
      :tool,
      :sequence,
      :point_group,
      :regimen,
      :pin_binding,
      :farm_even,
    ]},
    %Service{name: :firmware, status: :pending, waiting: [:fbos_config, :firmware_config]},

    %Event{name: :first_sync, status: :pending, waiting: [
      :device,
      :fbos_config,
      :firmware_config,
      :farmware_env,
      :first_party_farmware,
      :farmware_installation,
      :peripheral,
      :point,
      :sensor,
      :tool,
      :sequence,
      :point_group,
      :regimen,
      :pin_binding,
      :farm_even,
    ]},
    %Event{name: :flash_firmware, status: :pending, waiting: [:fbos_config]},
    %Event{name: :boot_sequence, status: :pending, waiting: [
        :firmware, 
        :fbos_config, 
        :sequence
    ]}
  ]

  use GenServer

  def update_service(tracker \\ __MODULE__, name, status) do
    GenServer.call(tracker, {:update_service, name, status})
  end

  def start_link(args, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, args, opts)
  end

  def init(_args) do
    {:ok, @initial_state}
  end

  def handle_call({:update_service, name, status}, state) do
    state = Enum.reduce(state, [], fn
      %Service{name: ^name, status: old} = service, acc -> 
        IO.puts "Service #{name} status update: #{old} => #{status}"
        [%{service | status: status} | acc]
      %kind{status: :pending, waiting: waiting} = entry, acc ->
        if name in waiting do
          IO.puts "#{kind} no longer waiting on #{name}"
        end
        [entry | acc]
    end)
    {:noreply, state}
  end
end