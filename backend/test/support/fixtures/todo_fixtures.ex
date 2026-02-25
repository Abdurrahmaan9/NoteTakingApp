defmodule TodoBackend.TodoFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TodoBackend.Todo` context.
  """

  @doc """
  Generate a item.
  """
  def item_fixture(attrs \\ %{}) do
    {:ok, item} =
      attrs
      |> Enum.into(%{
        completed: true,
        description: "some description",
        title: "some title"
      })
      |> TodoBackend.Todo.create_item()

    item
  end
end
