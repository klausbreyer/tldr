defmodule Tldr.Config do
  @moduledoc """
  Reads the development `.env`. `config/runtime.exs` uses it.
  """

  @doc """
  The main checkout of this repository. Every worktree shares its `.env`,
  so one key works everywhere. Outside git it is `cd` itself.
  """
  def shared_root(cd \\ File.cwd!()) do
    case System.cmd("git", ["rev-parse", "--path-format=absolute", "--git-common-dir"],
           cd: cd,
           stderr_to_stdout: true
         ) do
      {out, 0} -> out |> String.trim() |> Path.dirname()
      _ -> cd
    end
  rescue
    _ -> cd
  end

  @doc "Reads a dotenv file into a map. A missing file is an empty map."
  def dotenv(path) do
    case File.read(path) do
      {:ok, content} -> parse_dotenv(content)
      {:error, _} -> %{}
    end
  end

  defp parse_dotenv(content) do
    for line <- String.split(content, "\n"),
        line = String.trim(line),
        line != "" and not String.starts_with?(line, "#"),
        [key, value] <- [String.split(String.replace_prefix(line, "export ", ""), "=", parts: 2)],
        into: %{} do
      {String.trim(key), value |> String.trim() |> String.trim("\"") |> String.trim("'")}
    end
  end
end
