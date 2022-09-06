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

  def redirect(%{status: status} = conn, url) do
    body = "<html><body>You are being <a href=\"#{url}\">redirected</a>.</body></html>"

    conn
    |> put_resp_header("location", url)
    |> put_resp_content_type("text/html")
    |> send_resp((status || 302), body)
  end

end