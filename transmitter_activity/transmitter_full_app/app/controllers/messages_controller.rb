class MessagesController < ApplicationController
  # require 'faraday'

  def pass_message
    incoming_message = params[:data]

    puts incoming_message

    outgoing_message = incoming_message[:content][-5..-1] + 'wow'

    ip_addrs = incoming_message[:ip_addrs]
    next_addr = ip_addrs.first
    new_ip_addr_list = ip_addrs[1..-1]

    sleep 1

    send_message(incoming_message[:id], new_ip_addr_list, outgoing_message, "http://#{next_addr}:3000/messages")

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
