defmodule ChatbotFb.ChatRouter do
  use Plug.Router

  plug(:match)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Poison)
  plug(:dispatch)


  get "/webhook" do
    req_params = fetch_query_params(conn)
    IO.inspect(req_params)
    send_resp(conn,200,"EVENT_RECEIVED")
  end

  post "/webhook" do
    send_resp(conn,200,"EVENT_RECEIVED")
    # process_request(conn)
  end

  match _ do
    send_resp(conn,200,"ERROR")
  end

end
