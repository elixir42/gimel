defmodule Gimel do
  @moduledoc """
  Gimel finds Unicode characters by name.
  """

  @doc """
  Build list of uppercase words from a string, splitting hyphenated words.
  """
  def tokenize(text) do
    text
    |> String.upcase()
    |> String.replace("-", " ")
    |> String.split()
  end

  @doc """
  Parse line from UnicodeData.txt
  """
  def parse(line) do
    [code_str, name | _] = String.split(line, ";")
    code = String.to_integer(code_str, 16)
    {code, name, tokenize(name)}
  end

  @doc """
  Add character words to inverted index
  """
  def index(inverted_index, char_code, words) do
    Enum.reduce(words, inverted_index, fn word, idx ->
      Map.get_and_update(idx, word, fn
        nil -> {word, MapSet.new([char_code])}
        code_set -> {word, MapSet.put(code_set, char_code)}
      end)
      |> elem(1)
    end)
  end

  @doc """
  Build indices: first maps each word to a set of characters,
  second maps each character to its name.
  """
  def build_indices(lines) do
    word_idx = %{}
    char_idx = %{}
    indexes = {word_idx, char_idx}

    Enum.reduce(lines, indexes, fn line, {word_idx, char_idx} ->
      {code, name, words} = parse(line)
      {index(word_idx, code, words), Map.put(char_idx, code, name)}
    end)
  end

  @doc """
  Returns set of characters with all query words in their names.
  """
  def search(inverted_index, query) do
    [first | rest] = tokenize(query)
    result_set = inverted_index[first]

    if result_set do
      Enum.reduce_while(rest, result_set, fn word, result_set ->
        new_set = MapSet.intersection(result_set, inverted_index[word])

        if MapSet.size(new_set) > 0 do
          {:cont, new_set}
        else
          {:halt, new_set}
        end
      end)
      |> Enum.sort()
    else
      []
    end
  end
end
