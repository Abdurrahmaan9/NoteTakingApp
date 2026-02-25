defmodule TodoBackendWeb.NoteJSON do
  alias TodoBackend.Notes.Note

  @doc """
  Renders a list of notes.
  """
  def index(%{notes: notes}) do
    %{data: for(note <- notes, do: data(note))}
  end

  @doc """
  Renders a single note.
  """
  def show(%{note: note}) do
    %{data: data(note)}
  end

  defp data(%Note{} = note) do
    %{
      id: note.id,
      title: note.title,
      content: note.content,
      created_at: note.inserted_at,
      updated_at: note.updated_at
    }
  end
end
