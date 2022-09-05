defmodule MicroserviceWeb.Errors do
  
  def translate_error(%{errors: errors} = _changeset) do
    Enum.map(errors, fn {field, error} ->
      Atom.to_string(field) <> " " <> translate_error(error)
    end)
  end
  def translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
    end)
  end

end