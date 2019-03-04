defmodule VICI.Start do
  def run do
    VICI.Server.start_link 5001
  end
end
