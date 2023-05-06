defmodule ProfileImage.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :descrption, :string
    field :username, :string
    field :uploaded_files, {:array, :string}, default: []
    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :descrption])
    |> validate_required([:username, :descrption])
    |> validate_length(:descrption, min: 5, max: 50)
  end
end
