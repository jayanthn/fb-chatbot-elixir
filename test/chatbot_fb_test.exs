defmodule ChatbotFbTest do
  use ExUnit.Case
  use Plug.Test

  doctest ChatbotFb

  @token_val "859035600"

  @opts ChatbotFb.ChatRouter.init([])


  test "assert webhook working" do

    conn = conn(:get, "/webhooks?hub.challenge=CHALLENGE&hub.mode=subscribe&hub.verify_token=#{@token_val}")
    conn = ChatbotFb.ChatRouter.call(conn,@opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "CHALLENGE"
  end

  test "assert webhook failure on wrong token" do
    conn = conn(:get, "/webhooks?hub.challenge=CHALLENGE&hub.mode=subscribe&hub.verify_token=123}")
    conn = ChatbotFb.ChatRouter.call(conn,@opts)

    assert conn.state == :sent
    assert conn.status == 403
    assert conn.resp_body == "error"
  end

  test "check Coingecko Get API error on invalid coin ID" do
    assert {:error,:not_found} == GeckoAPI.get("bitc")
  end

  test "check Coingecko Get API working with correct coinID" do
    refute {:error,:not_found} == GeckoAPI.get("bitcoin")
  end

end
