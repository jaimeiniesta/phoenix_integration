defmodule PhoenixIntegration.Details.TagTest do
  use ExUnit.Case, async: true
  import PhoenixIntegration.Assertions.Map
  alias PhoenixIntegration.Form.Tag
  

  describe "common transformations" do
    test "single-valued names" do
      floki_tag = """
        <some_tag_name name="top_level[animal]" value="x">
      """
      |> Floki.parse_fragment!

      floki_tag
      |> new_for_success("some_tag_name")
      |> assert_fields(has_array_value: false,
                       values: ["x"],
                       name: "top_level[animal]",
                       path: [:top_level, :animal],
                       tag: "some_tag_name",
                       original: floki_tag)
    end

    
    test "multi-valued ([]-ending) names" do
      floki_tag = """
        <some_tag_name name="top_level[animals][]" value="x">
      """
      |> Floki.parse_fragment!

      floki_tag
      |> new_for_success("some_tag_name")
      |> assert_fields(has_array_value: true,
                       values: ["x"],
                       name: "top_level[animals][]",
                       path: [:top_level, :animals],
                       tag: "some_tag_name",
                       original: floki_tag)
    end
  end

  test "fields with types record them" do
    """
    <input type="text" name="top_level[name]" value="name">
    """
    |> Floki.parse_fragment!
    |> new_for_success("input")
    |> assert_field(type: "text")
  end


  describe "checkbox special cases" do
    # Special cases for checkboxes as described in
    # https://developer.mozilla.org/en-US/docs/Web/HTML/Element/Input/checkbox
    test "a checkbox that's omitted `checked`" do
      assert_input_values """
        <input type="checkbox" name="top_level[grades][a]" value="x">
      """, []
    end

    test "a checkbox that has any value for `checked`" do
      assert_input_values """
        <input type="checkbox" name="top_level[grades][a]" checked="true" value="x">
      """, ["x"]
    end

    test "a checkbox that is checked but has no explicit value" do
      assert_input_values """
        <input type="checkbox" name="top_level[grades][a]" checked="true">
      """, ["on"]
    end

    test "a checkbox that's part of an array has the same effect" do
      assert_input_values """
        <input type="checkbox" name="top_level[grades][]" value="x">
      """, []

      assert_input_values """
        <input type="checkbox" name="top_level[grades][]" checked="true" value="x">
      """, ["x"]

      assert_input_values """
        <input type="checkbox" name="top_level[grades][]" checked="anything">
      """, ["on"]
    end
  end

  defp new_for_success(floki_tag, tag_name) do
    {:ok, tag} = Tag.new(floki_tag, tag_name)
    tag
  end
  
  defp input_to_tag(fragment),
    do: Floki.parse_fragment!(fragment) |> new_for_success("input")

  defp assert_input_values(fragment, values) do
    assert input_to_tag(fragment).values == values
  end
  
end
