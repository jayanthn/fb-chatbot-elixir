defmodule ChatbotFb.ChatRouter do
alias ChatbotFb.ChatSession

  require Logger
  @token_val "859035600"

  use Plug.Router

  plug(:match)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:dispatch)


  get "/webhooks" do
    case validate_get_request(conn.params) do
      :ok -> send_resp(conn,200,conn.params["hub.challenge"])
      :error -> send_resp(conn,403,"error")
    end
  end

  post "/webhooks" do
    IO.inspect(conn)
    if conn.body_params["object"] == "page" do
        send_resp(conn,200,"OK")
        process_message(conn.body_params["messaging"])
    else
      send_resp(conn,200,"")
    end
    conn
  end

  match _ do
    send_resp(conn,200,"ERROR")
  end

  defp validate_get_request(req_params) do
    dbg(req_params)
    case {req_params["hub.mode"],req_params["hub.verify_token"]} do
      {"subscribe",@token_val} -> :ok
      _ -> :error
    end
  end

  defp process_message([]) do end
  defp process_message([message|messages]) do
    sender = message["sender"]
    id = sender["id"]
    case process_user(id,message) do
      {:ok,pid} ->
        ChatSession.add_session(id,pid)
      _ -> :ok
      end
      process_message(messages)
end
  defp process_user(id,message) do
    case ChatSession.get_session(id) do
      nil -> ChatSession.assign_session(id)
      _ -> ChatSession.handle_message(id,message)
    end
  end

end
