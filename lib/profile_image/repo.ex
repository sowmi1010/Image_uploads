defmodule ProfileImage.Repo do
  use Ecto.Repo,
    otp_app: :profile_image,
    adapter: Ecto.Adapters.Postgres
end
