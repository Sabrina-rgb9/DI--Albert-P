// Description: WebSocket server helper for the game server.

const WebSocket = require('ws')
const { v4: uuidv4 } = require('uuid')

class Obj {

    init(httpServer, port) {

        // Callbacks that can be assigned by the server logic.
        // onConnection: called when a client connects.
        // onMessage: called when a client sends a message.
        // onClose: called when a client disconnects.
        this.onConnection = (socket, id) => { }
        this.onMessage = (socket, id, obj) => { }
        this.onClose = (socket, id) => { }

        // Start the WebSocket server attached to the existing HTTP server.
        this.ws = new WebSocket.Server({ server: httpServer, perMessageDeflate: true })
        this.socketsClients = new Map()
        console.log(`Listening for WebSocket queries on ${port}`)

        // Register connection handler for new clients.
        this.ws.on('connection', (ws) => { this.newConnection(ws) })
    }

    // Gracefully close the websocket server.
    end() {
        this.ws.close()
    }

    // Send a text message to a specific socket if it is open.
    send(socket, msg) {
        if (socket && socket.readyState === WebSocket.OPEN) {
            socket.send(msg)
            return true
        }
        return false
    }

    // Check whether a socket is currently open and ready to send.
    isOpen(socket) {
        return !!socket && socket.readyState === WebSocket.OPEN
    }

    // Get how much data is buffered on the socket.
    // This is useful to detect send backpressure and avoid overloading the connection.
    getBufferedAmount(socket) {
        if (!socket) {
            return 0
        }
        if (typeof socket.bufferedAmount === 'number') {
            return socket.bufferedAmount
        }
        if (socket._socket && typeof socket._socket.writableLength === 'number') {
            return socket._socket.writableLength
        }
        return 0
    }

    // Determine whether the socket has more buffered data than the threshold.
    hasBackpressure(socket, threshold = 0) {
        return this.getBufferedAmount(socket) > Math.max(0, threshold)
    }

    // Handle a newly connected client.
    // Generates a unique client ID, stores metadata, sends a welcome message,
    // broadcasts the new client event to all connected clients, and hooks up message/close events.
    newConnection(con) {
        const id = "C" + uuidv4().substring(0, 5).toUpperCase();

        console.log(`Client connected: ${id}`);
        const metadata = { id };
        this.socketsClients.set(con, metadata);

        con.send(JSON.stringify({
            type: "welcome",
            id: id,
            message: "Welcome to the server"
        }));

        this.broadcast(JSON.stringify({
            type: "newClient",
            id: id
        }));

        if (this.onConnection && typeof this.onConnection === "function") {
            this.onConnection(con, id);
        }

        con.on("close", () => {
            this.closeConnection(con);
            this.socketsClients.delete(con);
        });

        con.on('message', (bufferedMessage) => {
            this.newMessage(con, id, bufferedMessage);
        });
    }

    // Internal helper called when a connection closes.
    // It triggers the onClose callback if available and logs the disconnection.
    closeConnection(con) {
        if (this.onClose && typeof this.onClose === "function") {
            var id = this.socketsClients.get(con).id
            this.onClose(con, id)
            console.log(`Client disconnected: ${id}`)
        }
    }

    // Broadcast a string message to every connected client.
    broadcast(msg) {
        this.forEachClient((client) => {
            client.send(msg)
        })
    }

    // Utility to iterate over all currently open clients.
    forEachClient(callback) {
        this.socketsClients.forEach((metadata, client) => {
            if (client.readyState === WebSocket.OPEN) {
                callback(client, metadata.id, metadata)
            }
        })
    }

    // Handle an incoming raw websocket message.
    // Converts the message to string and forwards it to the registered onMessage callback.
    newMessage(ws, id, bufferedMessage) {
        var messageAsString = bufferedMessage.toString()
        if (this.onMessage && typeof this.onMessage === "function") {
            this.onMessage(ws, id, messageAsString)
        }
    }

    // Retrieve metadata for a client by its generated ID.
    getClientData(id) {
        for (let [client, metadata] of this.socketsClients.entries()) {
            if (metadata.id === id) {
                return metadata;
            }
        }
        return null;
    }

    // Return a list with IDs of all connected clients.
    getClientsIds() {
        let clients = [];
        this.socketsClients.forEach((value, key) => {
            clients.push(value.id);
        });
        return clients;
    }

    // Return metadata objects for all connected clients.
    getClientsData() {
        let clients = [];
        for (let [client, metadata] of this.socketsClients.entries()) {
            clients.push(metadata);
        }
        return clients;
    }
}

module.exports = Obj
