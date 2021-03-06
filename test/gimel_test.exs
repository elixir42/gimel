defmodule GimelTest do
  use ExUnit.Case
  doctest Gimel

  test "tokenize" do
    text = "greater-than sign"
    tokens = ~w(GREATER THAN SIGN)
    assert Gimel.tokenize(text) == tokens
  end

  test "parse line" do
    line_lt = "003C;LESS-THAN SIGN;Sm;0;ON;;;;;Y;;;;;"
    tokens = ~w(LESS THAN SIGN)
    assert {0x3C, "LESS-THAN SIGN", ^tokens} = Gimel.parse(line_lt)
  end

  test "index one character" do
    tokens = ~w(DIGIT ZERO)

    expected = %{
      "DIGIT" => MapSet.new([?0]),
      "ZERO" => MapSet.new([?0])
    }

    assert expected == Gimel.index(%{}, ?0, tokens)
  end

  test "index two characters" do
    expected = %{
      "DIGIT" => MapSet.new([?0, ?1]),
      "ZERO" => MapSet.new([?0]),
      "ONE" => MapSet.new([?1])
    }

    result =
      %{}
      |> Gimel.index(?0, ~w(DIGIT ZERO))
      |> Gimel.index(?1, ~w(DIGIT ONE))

    assert expected == result
  end

  @sample_data """
               0037;DIGIT SEVEN;Nd;0;EN;;7;7;7;N;;;;;
               0038;DIGIT EIGHT;Nd;0;EN;;8;8;8;N;;;;;
               0039;DIGIT NINE;Nd;0;EN;;9;9;9;N;;;;;
               003A;COLON;Po;0;CS;;;;;N;;;;;
               003B;SEMICOLON;Po;0;ON;;;;;N;;;;;
               003C;LESS-THAN SIGN;Sm;0;ON;;;;;Y;;;;;
               003D;EQUALS SIGN;Sm;0;ON;;;;;N;;;;;
               003E;GREATER-THAN SIGN;Sm;0;ON;;;;;Y;;;;;
               """
               |> String.trim()
               |> String.split(["\n", "\r", "\r\n"])

  test "build_indexes" do
    {word_idx, code_idx} = Gimel.build_indexes(@sample_data)
    assert code_idx[?7] == "DIGIT SEVEN"
    assert word_idx["SEVEN"] == MapSet.new([?7])
    assert word_idx["DIGIT"] == MapSet.new([?7, ?8, ?9])
    assert word_idx["THAN"] == MapSet.new([?<, ?>])
  end

  test "search: single words" do
    {word_idx, _code_idx} = Gimel.build_indexes(@sample_data)
    assert Gimel.search(word_idx, "COLON") == [?:]
    assert Gimel.search(word_idx, "DIGIT") == [?7, ?8, ?9]
    assert Gimel.search(word_idx, "DOESNOTEXIST") == []
  end

  test "search: multiple words" do
    {word_idx, _code_idx} = Gimel.build_indexes(@sample_data)
    assert Gimel.search(word_idx, "SEVEN DIGIT") == [?7]
    assert Gimel.search(word_idx, "SIGN THAN") == [?<, ?>]
    assert Gimel.search(word_idx, "DOES NOT EXIST") == []
    assert Gimel.search(word_idx, "DIGIT QAZWSX") == []
  end

  test "search: no words" do
    {word_idx, _code_idx} = Gimel.build_indexes(@sample_data)
    assert Gimel.search(word_idx, "") == []
    assert Gimel.search(word_idx, "-") == []
    assert Gimel.search(word_idx, "--") == []
    assert Gimel.search(word_idx, "- -") == []
  end

  @tag :slow
  test "search: full database" do
    {word_idx, _code_idx} = Gimel.load_data()
    result = Gimel.search(word_idx, "number eleven")
    assert result == [9322, 9342, 9362, 9451, 93_835]

    text =
      result
      |> Enum.map(&<<&1::utf8>>)
      |> Enum.join(" ")

    assert text == "⑪ ⑾ ⒒ ⓫ 𖺋"
  end
end
