defmodule GeckoAPI do

  def get(id) do
    url = "https://api.coingecko.com/api/v3/coins/#{id}/market_chart?vs_currency=usd&days=14&interval=daily"
    resp =
    case HTTPoison.get(url,[]) do
      {:ok,r} -> r
      _ -> throw({:error,:unreach})
    end
    {:ok,json_body} = Jason.decode(resp.body)
    if json_body["error"] == nil do
      prices = json_body["prices"]
      make_history_message(prices,"")
    else
      {:error,:not_found}
    end
  end

  def search(name) do
    url = "https://api.coingecko.com/api/v3/search?query=#{name}"
    case HTTPoison.get(url,[]) do
      {:ok,resp} ->
        {:ok,json_body} = Jason.decode(resp.body)
        json_body["coins"]
        |> Enum.slice(0,5)
        |> make_coin_message([])
      _ -> {:error,:unreach}
    end
  end

  defp make_history_message([],acc) do {:ok,acc} end
  defp make_history_message([[time,price]|prices],acc) do
    time =
    time
    |> div(1000)
    |> DateTime.from_unix!()
    |> Date.to_string()
    make_history_message(prices,acc <> "#{time}  $#{price}\n")
  end


  defp make_coin_message([],acc) do {:ok,acc} end
  defp make_coin_message([coin|coins],acc) do
    name = coin["name"]
    id = coin["id"]
    payload =  "coin_postback_" <> id
    coinmap = %{"type" => "postback" , "payload" => payload , "title" => name}
    make_coin_message(coins,[coinmap|acc])
  end


end



# curl -X 'GET' \
#   'https://api.coingecko.com/api/v3/coins/bitcoin/market_chart?vs_currency=usd&days=14&interval=daily' \
#   -H 'accept: application/json'
