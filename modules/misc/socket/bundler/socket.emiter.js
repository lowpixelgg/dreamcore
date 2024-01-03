const sockets = []

class Socket {
  constructor(host, transport) {
    this.socket = null
    if (host && transport) {
      this.connect(host, transport)
    }
  }
  
  connect (host, transport) {
    this.socket = io(host, { transports: [transport]})
  }

  emit (event, data) {
    this.socket.emit(event, data)
  }

  on (event) {
    this.socket.on(event, (data) => {
      mta.triggerEvent(event, data)
    })
  }

  onAny () {
    this.socket.onAny((eventName, data) => {
      mta.triggerEvent("__any", eventName, data)
    })
  }
}

const createClass = (id, host, transport) => {
  const exists = sockets[id]

  if (exists === undefined) {
    sockets[id] = new Socket(host, transport)
    console.log('creating socket')
    
    if (sockets[id]) {
      mta.triggerEvent("__created")
    }
    
    return true
  } else {
    console.log('using existing socket')
    return sockets["" + id + ""]
  }
}