defmodule ProfileImageWeb.UserLive.FormComponent do
  use ProfileImageWeb, :live_component

  alias ProfileImage.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage user records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="user-form"
        phx-target={@myself}
        phx-change="validate"
        phx-drop-target={@uploads.image.ref}
        phx-submit="save"
      >
        <.input field={@form[:username]} type="text" label="Username" />
        <.input field={@form[:descrption]} type="textarea" label="Descrption" />
        <.live_file_input upload={@uploads.image} />
        <%= for entry <- @uploads.image.entries do %>
          <figure>
            <.live_img_preview entry={entry} class="h-46 object-cover w-96" />
            <figcaption class="text-sm font-bold text-green-400"><%= entry.client_name %></figcaption>
          </figure>
          <progress value={entry.progress} max="100" class="bg-green-600 h-2.5 rounded-full">
            <%= entry.progress %>%
          </progress>
          <button
            type="button"
            phx-click="cancel-upload"
            phx-value-ref={entry.ref}
            aria-label="cancel"
          >
            &times;
          </button>
          <%= for err <- upload_errors(@uploads.image, entry) do %>
            <p class="text-red-500 text-lg font-semibold"><%= error_to_string(err) %></p>
          <% end %>
        <% end %>
        <%= for err <- upload_errors(@uploads.image) do %>
          <p class="text-red-500 text-lg font-semibold"><%= error_to_string(err) %></p>
        <% end %>
        <:actions>
          <.button phx-disable-with="Saving...">Save User</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{user: user} = assigns, socket) do
    changeset = Accounts.change_user(user)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)
     |> assign(:uploaded_files, [])
     |> allow_upload(:image,
       accept: ~w(.png .jpg),
       max_entries: 1,
       max_file_size: 8_888_888
     )}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.change_user(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :image, fn %{path: path}, _entry ->
        dest =
          Path.join([:code.priv_dir(:profile_image), "static", "uploads", Path.basename(path)])

        File.cp!(path, dest)
        {:ok, ~p"/uploads/" <> Path.basename(dest)}
      end)

    {:noreply, update(socket, :uploaded_files, &(&1 ++ uploaded_files))}

    save_user(socket, socket.assigns.action, user_params)
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  def handle_event("cancel-upload", %{"ref" => ref, "value" => _value}, socket) do
    {:noreply, cancel_upload(socket, :image, ref)}
  end

  defp save_user(socket, :edit, user_params) do
    case Accounts.update_user(socket.assigns.user, user_params) do
      {:ok, user} ->
        notify_parent({:saved, user})

        {:noreply,
         socket
         |> put_flash(:info, "User updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_user(socket, :new, user_params) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        notify_parent({:saved, user})

        {:noreply,
         socket
         |> put_flash(:info, "User created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def error_to_string(:too_large), do: "Too large"
  def error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  def error_to_string(:too_many_files), do: "You have selected too many files"

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
