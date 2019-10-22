defmodule FarmbotCore.Asset.Repo.Migrations.AddNewFirmwareParams do
  use Ecto.Migration

  def change do
    alter table("firmware_configs") do
      add(:movement_microsteps_x, :float)
      add(:movement_microsteps_y, :float)
      add(:movement_microsteps_z, :float)
    end
  end
end
