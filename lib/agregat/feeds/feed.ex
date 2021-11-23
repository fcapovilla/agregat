defmodule Agregat.Feeds.Feed do
  use Ecto.Schema
  import Ecto.Changeset

  alias Agregat.Feeds

  schema "feeds" do
    field :auto_frequency, :boolean, default: false
    field :last_sync, :utc_datetime
    field :position, :integer, default: 0
    field :sync_status, :string
    field :title, :string
    field :unread_count, :integer, default: 0
    field :update_frequency, :integer, default: 30
    field :url, :string
    field :folder_title, :string, virtual: true, default: ""
    field :is_html, :boolean, default: false
    field :parsing_settings, :map
    belongs_to :user, Agregat.Users.User
    belongs_to :folder, Agregat.Feeds.Folder, on_replace: :update
    belongs_to :favicon, Agregat.Feeds.Favicon
    has_many :items, Agregat.Feeds.Item

    timestamps()
  end

  @doc false
  def changeset(feed, attrs) do
    feed
    |> cast(attrs, [
      :title,
      :url,
      :last_sync,
      :unread_count,
      :sync_status,
      :position,
      :update_frequency,
      :auto_frequency,
      :user_id,
      :folder_id,
      :favicon_id,
      :folder_title,
      :is_html,
      :parsing_settings
    ])
    |> validate_required([:url])
    |> update_folder()
  end

  defp update_folder(
         %Ecto.Changeset{valid?: true, changes: %{folder_title: folder_title}} = changeset
       ) do
    folder =
      Feeds.first_or_create_folder!(%{
        title: folder_title,
        user_id: get_field(changeset, :user_id)
      })

    put_change(changeset, :folder_id, folder.id)
  end

  defp update_folder(changeset), do: changeset
end
