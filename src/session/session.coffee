{EventEmitter} = require "events"
{assign, isString} = require "lodash"

class Session extends EventEmitter
  constructor: (socket) ->
    @socket = socket
    @context = {}
  
  send: (frame) ->
    @socket.send frame, (err) =>
      if err
        @emit "error", err
  
  connected: (headers) ->    
    @send
      command: "CONNECTED"
      headers: assign({ version: "1.2" }, headers)
  
  message: (body, headers) ->
    unless isString body
      body = JSON.stringify body
      contentType = "application/json; charset=utf-8"
      headers = assign { "content-type": contentType }, headers 
    @send
      command: "MESSAGE"
      headers: headers
      body: body
  
  error: (err) ->
    @send
      command: "ERROR"
      headers: { message: err.message }
  
  observe: (observable, headers) ->
    sendMessage = (body) =>
      @message body, headers
    sendError = (err) =>
      @error err
  
    observable.onValue sendMessage
    observable.onError sendError
    
    unsubscribe = ->
      observable.offValue sendMessage
      observable.offError sendError
    
    return unsubscribe
  
  receipt: (frame) ->
    {receipt} = frame.headers
    if receipt
      @send
        command: "RECEIPT"
        headers: { "receipt-id": receipt }
  
  close: ->
    @socket.close()

module.exports = Session