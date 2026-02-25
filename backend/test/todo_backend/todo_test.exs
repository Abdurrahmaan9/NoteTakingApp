defmodule TodoBackend.TodoTest do
  use TodoBackend.DataCase

  alias TodoBackend.Todo

  describe "items" do
    alias TodoBackend.Todo.Item

    import TodoBackend.TodoFixtures

    @invalid_attrs %{description: nil, title: nil, completed: nil}

    test "list_items/0 returns all items" do
      item = item_fixture()
      assert Todo.list_items() == [item]
    end

    test "get_item!/1 returns the item with given id" do
      item = item_fixture()
      assert Todo.get_item!(item.id) == item
    end

    test "create_item/1 with valid data creates a item" do
      valid_attrs = %{description: "some description", title: "some title", completed: true}

      assert {:ok, %Item{} = item} = Todo.create_item(valid_attrs)
      assert item.description == "some description"
      assert item.title == "some title"
      assert item.completed == true
    end

    test "create_item/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Todo.create_item(@invalid_attrs)
    end

    test "update_item/2 with valid data updates the item" do
      item = item_fixture()
      update_attrs = %{description: "some updated description", title: "some updated title", completed: false}

      assert {:ok, %Item{} = item} = Todo.update_item(item, update_attrs)
      assert item.description == "some updated description"
      assert item.title == "some updated title"
      assert item.completed == false
    end

    test "update_item/2 with invalid data returns error changeset" do
      item = item_fixture()
      assert {:error, %Ecto.Changeset{}} = Todo.update_item(item, @invalid_attrs)
      assert item == Todo.get_item!(item.id)
    end

    test "delete_item/1 deletes the item" do
      item = item_fixture()
      assert {:ok, %Item{}} = Todo.delete_item(item)
      assert_raise Ecto.NoResultsError, fn -> Todo.get_item!(item.id) end
    end

    test "change_item/1 returns a item changeset" do
      item = item_fixture()
      assert %Ecto.Changeset{} = Todo.change_item(item)
    end
  end
end
