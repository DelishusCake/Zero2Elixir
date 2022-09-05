defmodule MicroserviceWeb.Renderer do
  import Plug.Conn

  @template_dir "lib/microservice_web/templates/"

  def render_template(template, assigns \\ []) do
    Path.join(@template_dir, template)
    |> String.replace_suffix("", ".eex")
    |> EEx.eval_file(assigns)
  end

  def render_html(%{status: status} = conn, template, assigns \\ []) do
    body = render_template(template, assigns)
    conn
    |> put_resp_content_type("text/html") 
    |> send_resp((status || 200), body)
  end

  def render_json(%{status: status} = conn, data) do
    body = Jason.encode!(data)
    conn
    |> put_resp_content_type("application/json") 
    |> send_resp((status || 200), body)
  end

end