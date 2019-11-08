defmodule ElastixTest do
  use ExUnit.Case

  test "version_to_tuple/1" do
    assert Elastix.version_to_tuple("1.0") == {1, 0, 0}
    assert Elastix.version_to_tuple("1.1") == {1, 1, 0}
    assert Elastix.version_to_tuple("1.2.3") == {1, 2, 3}
  end

end
