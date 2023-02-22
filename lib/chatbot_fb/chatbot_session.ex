defmodule ChatSession do

  require Logger

  use GenServer


  @hibernate_limit 60000
  @shutdown_limit (5 * 60000)

  ## Authorization and PageId token to server
  @fb_token "EAAJxcfLa4ZCgBAA4rtZBTlnzvBEFJBLqXPzO6iZAsBK6sQdAySmBTzFAFSfDIIGsUMkZC7bNtnwwJdgq0G3hmsNnHZAKZBjwKUHmzWOSCOX5zwmlEbNtea4vmZBxyHPzPBhINkfRfQhHFdAq2XzIT4HTca7aW4ur4DgwXL2iGAuDybzK9thcrkx"
  @pageid 100983352929481

  @doc """
  Starts a mapper gen server that maps different users to the process id for their own gen servers.
  Each user gets their own gen server for maintaing state
  """
  def start_link(_) do
    GenServer.start_link(__MODULE__,%{},[name: :user_mapper])
  end

  # Start the gen server and starting the conversation
  @doc """
  Called when a user sends the first ever message to the chatbot.
  Creates a gen server for that user with state maintainance.
  """
  def assign_session(userid) do
    {:ok,pid} = start(userid)
    GenServer.call(:user_mapper, {:adduser,userid,pid})
    greetings(userid,"Hello {{firstname}}! ")
  end


  ######### GenServer functions ############

  # gets the pid of the gen server mapped to the user
  def get_session(id), do: GenServer.call(:user_mapper, {:get,id})

  # Actual processing of messages happens here
  def process_user_message(pid,message), do: GenServer.cast(pid,message)

  def stop(name), do: GenServer.stop(name)

  ## private functions ##

  defp start(userid) do
    name = String.to_atom("userid_" <> to_string(userid))
    GenServer.start(__MODULE__,%{"userid" => userid},[name: name, timeout: @shutdown_limit, hibernate_after: @hibernate_limit])
  end


  ######### Module functions ############

  # Greets the user with their first name
  defp greetings(userid,greeting_msg) do
    greetings = greeting_msg <> "You can search for information about Cryptocurrency by mentioning its CoinGecko ID or searching it's name"
    buttons = greeting_postback_buttons()
    body = postback_buttons(greetings,userid,buttons)
    send_response(userid,body)
  end

  defp process_message_(message,state) do
    id = state["userid"]
    nameflag = state["nameflag"]
    idflag = state["idflag"]
    case try_classify_message(message) do
      :crypto_id        ->
        send_response(id,"Type the name of the crypto id")
        Map.put(state,"idflag",true)
      :crypto_name      ->
        send_response(id,"Type the name of the crypto to search for")
        Map.put(state,"nameflag",true)
      {:coin,coinname}  ->
        serve_coin(id,coinname)
        Map.delete(state,"idflag")
      {:search,message} ->
        cond do
          idflag == true ->
            serve_coin(id,message)
            greetings(id,"")
            Map.delete(state,"idflag")
          nameflag == true ->
            search_coin(id,message)
            greetings(id,"")
            Map.delete(state,"nameflag")
          true ->
            send_response(id,"Sorry, that is an invalid response, try again!")
            greetings(id,"")
            reset_state(state)
        end
      :invalid ->
        send_response(id,"Sorry, that is an invalid response, try again!")
        greetings(id,"")
        reset_state(state)
      :length_limit ->
        if nameflag do
          send_response(id,"Sorry, cannot process coin names that are too long!")
        else
          send_response(id,"Sorry, cannot process messages that are too long!")
        end
        greetings(id,"")
        reset_state(state)
    end
  end


  defp search_coin(id,searchcoin) do
    try do
      case GeckoAPI.search(searchcoin) do
        {:ok, buttons} ->
          body = postback_buttons("Following were the coins that were found: ",id,buttons)
          {:ok,jsonbody} = Jason.encode(body)
          send_json_response(jsonbody)
        {:error,error} ->
          Logger.error("Failed SearchAPI from CoinGecko...#{error}")
          send_response(id,"Sorry, Service is unavailable. Try again later.")
      end
    rescue
      error in RuntimeError ->
        Logger.error("Failed Search API from CoinGecko...#{error}")
        send_response(id,"Sorry, the service is unavailable, please try again")
    end
  end

  defp serve_coin(id,coinid) do
    message =
      try do
        case GeckoAPI.get(coinid) do
          {:error,:not_found} ->
            Logger.error("Failed GetAPI from CoinGecko. Coin not found")
            "Sorry, cannot find the requested coin"
          {:ok,resp} -> resp
        end
      rescue
        error in RuntimeError ->
          Logger.error("Failed Get API from CoinGecko...#{error}")
          "Sorry, the service is unavailable, please try again"
      end
    send_response(id,message)
  end

    # it seems that coin-gecko does not have coinids with more than 60 chars, but limited to 100 just in case
    defp try_classify_message(message) when byte_size(message) > 100, do: :length_limit
    defp try_classify_message("crypto_id"), do: :crypto_id
    defp try_classify_message("crypto_name"), do: :crypto_name
    defp try_classify_message(<<"coin_postback_",coinname::binary>>), do: {:coin,coinname}
    defp try_classify_message(message) when is_binary(message) do
      case validate_message(message) do
        :ok -> {:search,message}
        :error -> :invalid
      end
    end
    defp try_classify_message(_), do: :invalid

    defp validate_message(<<>>), do: :ok
    defp validate_message(<<char::8,rest::binary>>) when (char >= ?a and char <= ?z) or char == ?- , do: validate_message(rest)
    defp validate_message(_), do: :error

  def send_response(userid,message) do
    body =
      %{
        "recipient" =>
          %{"id" => userid},
        "messaging_type" => "RESPONSE",
        "message" =>
          %{
            "text" => message
          }
      }
    {:ok,jsonbody} = Jason.encode(body)
    send_json_response(jsonbody)
  end

  defp send_json_response(message) do
      url = "https://graph.facebook.com/v16.0/#{@pageid}/messages?access_token=#{@fb_token}"
      # dbg(url)
      # dbg(message)
      HTTPoison.post(url,message,[{"Content-Type", "application/json"}])
    end

  defp reset_state(state) do
    state
    |> Map.put("idflag",nil)
    |> Map.put("nameflag",nil)
  end

  defp postback_buttons(message, psid, buttons) do
    %{
      "message" => %{
        "attachment" => %{
          "type" => "template",
          "payload" => %{
            "template_type" => "button",
            "text" => message,
            "buttons" => buttons
          }
        }
      },
      "recipient" => %{"id" => psid}
    }
  end

  defp greeting_postback_buttons() do
    [
      %{
        "type" => "postback",
        "payload" => "crypto_id",
        "title" => "Search by Crypto ID"
      },
      %{
        "type" => "postback",
        "payload" => "crypto_name",
        "title" => "Search by Crypto Name"
      }
    ]
  end



  ######### GenServer Callbacks ############

  @impl true
  def init(state) do
    {:ok, state, @shutdown_limit}
  end

  @impl true
  def handle_cast({:message, message}, state) do
    newstate = process_message_(message,state)
    {:noreply,newstate, @shutdown_limit}
  end

  @impl true
  def handle_call({:adduser,userid,pid},_,state) do
    {:reply, :ok , Map.put(state, userid, pid)}
  end

  def handle_call({:get, key },_, state) do
    {:reply, Map.get(state,key) , state}
  end

  @impl true
  def handle_info(:timeout,state) do
    {:stop,:normal,state}
  end

  @impl true
  def terminate(_reason,_state), do: :ok

end

  # curl -X POST -H "Content-Type: application/json" -d '{
  #   "recipient":{
  #     "id":"PSID"
  #   },
  #   "messaging_type": "RESPONSE",
  #   "message":{
  #     "text":"Hello, world!"
  #   }
  # }' "https://graph.facebook.com/LATEST-API-VERSION/PAGE-ID/messages?access_token=PAGE-ACCESS-TOKEN"
