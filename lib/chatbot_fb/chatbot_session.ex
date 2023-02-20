defmodule ChatbotFb.ChatSession do

  @fb_token "EAAJxcfLa4ZCgBAA4rtZBTlnzvBEFJBLqXPzO6iZAsBK6sQdAySmBTzFAFSfDIIGsUMkZC7bNtnwwJdgq0G3hmsNnHZAKZBjwKUHmzWOSCOX5zwmlEbNtea4vmZBxyHPzPBhINkfRfQhHFdAq2XzIT4HTca7aW4ur4DgwXL2iGAuDybzK9thcrkx"

  use GenServer

  def start_mapper() do
    GenServer.start_link(__MODULE__,%{},[])
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:push, element}, state) do
    {:noreply, [element | state]}
  end


  def handle_call({:add, key, value}, state) do
    {:reply, :ok , Map.put(state,key,value)}
  end

  def handle_call({:get, key }, state) do
    {:reply, :ok , Map.get(state,key)}
  end


  def add_user(userid,pid) do
    GenServer.call(__MODULE__, {:add,userid,pid})
  end

  def get_session(id) do
    GenServer.call(__MODULE__, {:get,id})
  end

 # Start the server by starting the conversation
  def assign_session(userid) do
    name = String.to_atom("user" <> to_string(userid))
    {:ok, pid} = GenServer.start_link(name,userid)
    start_conversation(userid)
    pid
  end

  def start_conversation(userid) do
    greetings = "Hello {{firstname}}. You can search for information about Crypto Currency by mentioning its ID (obtained from CoinGecko) or it's Name"
    body = Jason.encode(hello_json_struct_postback(greetings,userid,&greeting_postback_buttons/0))
    url = "https://graph.facebook.com/v16.0/me/messages?access_token=" <> @fb_token
    dbg(body)
    # HTTPoison.post(url,body,[{"Content-Type", "application/json"}])
  end

  def handle_message(id,{:coinid, CoinId}) do
    ""
    # response = coingeckoapi(CoinId)
    # format_response(id,response)

  end

  defp hello_json_struct_postback(message, psid, button_fun) do
    %{
      "message" => %{
        "attachment" => %{
          "payload" => %{
            "type" => "template",
            "template_type" => "button",
            "text" => message,
            "buttons" => button_fun.()
          }
        }
      },
      "recipient" => %{"id" => psid}
    }
  end

  def greeting_postback_buttons() do
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
end
