class MessagesController < ApplicationController
  # require 'faraday'

  def pass_message
    incoming_message = params[:data]

    puts incoming_message

    outgoing_message = incoming_message[:content][-5..-1] + 'wow'

    ip_addrs = incoming_message[:ip_addrs]
    next_addr = ip_addrs.first
    new_ip_addr_list = ip_addrs[1..-1] << next_addr

    broker_ip_addr = 'some.ip.addr.here'

    sleep 1

    Thread.new{
      begin
        send_message(incoming_message[:id], new_ip_addr_list, outgoing_message, "http://#{next_addr}:3000/messages")
      rescue StandardError => e
        Thread.new{ send_message(incoming_message[:id], "http://#{broker_ip_addr}:3000/messages", "http://#{broker_ip_addr}:3001/broker_errors") }
      end
    }

    Thread.new{
      begin
        send_message(incoming_message[:id], new_ip_addr_list, outgoing_message, "http://#{broker_ip_addr}:3001/broker_messages")
      rescue StandardError => e
        puts e.message
      end
    }

    head :no_content, status: :ok
  end

  private

  def send_message(id, ip_addrs, content, destination)
    conn = Faraday.new(:url => destination)

    message = {
      data: {
        ip_addrs: ip_addrs,
        id: id,
        content: content,
      }
    }

    # post payload as JSON instead of "www-form-urlencoded" encoding:
    conn.post do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = message.to_json
    end
  end
end





# for testing purposes
def test_post(ip, name, redirect_ip)
  require 'faraday'

  conn = Faraday.new(:url => "http://192.168.2.#{ip}:3000/messages")

  message = {
    data: {
      ip_addrs: ["192.168.2.#{redirect_ip}"],
      id: 1,
      content: "Howdy #{name}",
    }
  }

  # post payload as JSON instead of "www-form-urlencoded" encoding:
  Thread.new do
    conn.post do |req|
      req.url '/messages'
      req.headers['Content-Type'] = 'application/json'
      req.body = message.to_json
    end
  end
  ''
end

@teams = [
  ["The Team That Must Not Be Named", "114"],
  ["AJAx",                            "121"],
  ["Eric's Folly",                    "192"],
  ["Octavian's Left",                 "211"]
]

def ping_teams(redirect_ip)
  @teams.each do |name, ip|
    test_post(ip, name, redirect_ip)
  end
end

# curl -H "Content-Type: application/json" -X POST -d '{"id":-1, "content":"all your base are"}' http://192.168.2.196:3000/messages


