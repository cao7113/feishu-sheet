defmodule FeishuSheetTest do
  use ExUnit.Case
  import FeishuSheet

  @tag :external
  test "try demo sheet" do
    stoken = "Ptbds1eKzhFCcwtgMZZc6U8nnNh"

    get_sheet_data!(stoken, 0, "A1", "C")
    |> IO.inspect(label: "demo spreedsheet")
  end

  test "parse rows data with headers" do
    assert parse_rows_data([]) == []
    assert parse_rows_data([[1, 2]]) == [%{"fieldA" => 1, "fieldB" => 2}]
    assert parse_rows_data([[:name, :age], [1, 2]], headers: true) == [%{age: 2, name: 1}]

    assert parse_rows_data([[:name, :age, nil], [1, 2, 3]], headers: true) === [
             %{:age => 2, :name => 1, "fieldC" => 3}
           ]

    assert parse_rows_data([[:n, :a], [1, 2]], headers: [:name, :age, :title]) == [
             %{age: 2, name: 1}
           ]

    assert parse_rows_data([[:name, :age], [1, 2]], headers: [:custom_name, :custom_age]) == [
             %{custom_age: 2, custom_name: 1}
           ]
  end

  test "default field name" do
    assert field_name(1) == "fieldA"
    assert field_name(3) == "fieldC"
  end
end
