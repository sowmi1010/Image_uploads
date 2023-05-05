defmodule ProfileImage.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string
      add :descrption, :string

      timestamps()
    end
  end
end
