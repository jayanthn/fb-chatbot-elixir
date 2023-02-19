defmodule ChatbotFb.ChatRouter do

  @token_val "859035600"

  use Plug.Router

  plug(:match)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Poison)
  plug(:dispatch)


  get "/webhooks" do
    Logger.info("Received GET Webhooks request at : ")
    case validate_get_request(conn.params) do
      :ok -> send_resp(conn,200,conn.params["hub.challenge"])
      :error -> send_resp(conn,403,"error")
    end
  end

  post "/webhooks" do
    send_resp(conn,200,"EVENT_RECEIVED")
    # process_request(conn)
  end

  match _ do
    send_resp(conn,200,"ERROR")
  end

  defp validate_get_request(req_params) do
    dbg(req_params)
    # dbg(req_params."hub.verify_token")
    case {req_params["hub.mode"],req_params["hub.verify_token"]} do
      {"subscribe",@token_val} -> :ok
      _ -> :error
    end
  end

end
