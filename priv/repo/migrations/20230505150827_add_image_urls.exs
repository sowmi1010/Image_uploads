defmodule ProfileImage.Repo.Migrations.AddImageUrls do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :uploaded_files, {:array, :string}, null: false, default: []
    end
  end
end
