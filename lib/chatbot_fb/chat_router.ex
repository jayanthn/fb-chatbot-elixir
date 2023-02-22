defmodule ChatbotFb.ChatRouter do

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
    fieldname = conn.body_params["field"]
    cond do
      fieldname == "messages" ->
        send_resp(conn,200,"OK")
        process_message(conn.body_params)
      fieldname == "messaging_postback" ->
        send_resp(conn,200,"OK")
        process_postback(conn.body_params)
      true ->
        send_resp(conn,404,"")
    end
    conn
  end

  match _ do
    send_resp(conn,200,"ERROR")
  end


  defp validate_get_request(req_params) do
    # dbg(req_params)
    case {req_params["hub.mode"],req_params["hub.verify_token"]} do
      {"subscribe",@token_val} -> :ok
      _ -> :error
    end
  end

  defp process_postback(message) do
    value_struct = message["value"]
    sender_struct = value_struct["sender"]
    sender = sender_struct["id"]
    try do
      postback_struct = message["postback"]
      actualmessage = postback_struct["payload"]
      process_user(sender,actualmessage)
    rescue
      error in RuntimeError ->
        ChatSession.send_response(sender,"Unable to process request. Please try again")
        Logger.error("Invalid message from #{sender}...#{error}")
    end
  end

  defp process_message(message) do
    sender =
    try do
      value_struct = message["value"]
      sender_struct = value_struct["sender"]
      sender_struct["id"]
    rescue
      error in RuntimeError ->
        Logger.error("Invalid message, cannot reply since user id can't be obtained...#{error}")
    end
    try do
      message = message["message"]
      actualmessage = message["text"]
      process_user(sender,actualmessage)
    rescue
      error in RuntimeError ->
        ChatSession.send_response(sender,"Unable to process request. Please try again")
        Logger.error("Invalid message from #{sender}...#{error}")
    end
  end

  defp process_user(id,message) do
    case ChatSession.get_session(id) do
      nil -> ChatSession.assign_session(id)
      pid ->
        if Process.alive?(pid) do
          ChatSession.process_user_message(pid,{:message,message})
        else
          ChatSession.assign_session(id)
        end
    end
  end

end
