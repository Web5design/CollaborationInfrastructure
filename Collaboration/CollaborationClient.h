/***********************************************************************
CollaborationClient - Class to support collaboration between
applications in spatially distributed (immersive) visualization
environments.
Copyright (c) 2007-2009 Oliver Kreylos

This file is part of the Vrui remote collaboration infrastructure.

The Vrui remote collaboration infrastructure is free software; you can
redistribute it and/or modify it under the terms of the GNU General
Public License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.

The Vrui remote collaboration infrastructure is distributed in the hope
that it will be useful, but WITHOUT ANY WARRANTY; without even the
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with the Vrui remote collaboration infrastructure; if not, write to the
Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
02111-1307 USA
***********************************************************************/

#ifndef COLLABORATIONCLIENT_INCLUDED
#define COLLABORATIONCLIENT_INCLUDED

#include <string>
#include <vector>
#include <Misc/HashTable.h>
#include <Misc/ConfigurationFile.h>
#include <Threads/Thread.h>
#include <Threads/Mutex.h>
#include <Threads/TripleBuffer.h>
#include <GLMotif/ToggleButton.h>
#include <Vrui/Geometry.h>
#include <Vrui/GlyphRenderer.h>

#include <Collaboration/CollaborationPipe.h>
#include <Collaboration/ProtocolClient.h>

/* Forward declarations: */
class GLContextData;
namespace GLMotif {
class PopupWindow;
class RowColumn;
}

namespace Collaboration {

class CollaborationClient
	{
	/* Embedded classes: */
	private:
	typedef std::vector<ProtocolClient*> ProtocolList; // Type for lists of client protocol plug-ins
	typedef ProtocolClient::RemoteClientState ProtocolRemoteClientState; // Type for protocol-specific states of remote clients
	
	struct Client // Structure containing persistent state of remote clients
		{
		/* Embedded classes: */
		public:
		struct ProtocolListEntry // Structure for entries in a client's shared protocol list
			{
			/* Elements: */
			public:
			ProtocolClient* protocol; // Pointer to protocol plug-in object
			ProtocolRemoteClientState* protocolClientState; // Pointer to protocol's state object for this remote client
			
			/* Constructors and destructors: */
			ProtocolListEntry(ProtocolClient* sProtocol,ProtocolRemoteClientState* sProtocolClientState)
				:protocol(sProtocol),protocolClientState(sProtocolClientState)
				{
				}
			};
		
		typedef std::vector<ProtocolListEntry> RemoteClientProtocolList; // Type for lists of shared protocols
		
		/* Elements: */
		public:
		unsigned int clientID; // Server-wide unique client ID
		std::string name; // Display name of client
		RemoteClientProtocolList protocols; // List of protocols and protocol states shared with this client
		
		/* Constructors and destructors: */
		~Client(void);
		};
	
	typedef std::vector<Client*> ClientList; // Type for lists of client states
	typedef Misc::HashTable<unsigned int,Client*> ClientHash; // Hash table to map from client IDs to client objects
	
	struct ClientListAction // Structure to hold recent changes to the client list
		{
		/* Embedded classes: */
		public:
		enum Action // Enumerated type for client list actions
			{
			ADD_CLIENT,REMOVE_CLIENT
			};
		
		/* Elements: */
		Action action; // Which action was taken
		unsigned int clientID; // ID of the client that was added or removed
		Client* client; // Pointer to client state of added client
		
		/* Constructors and destructors: */
		ClientListAction(Action sAction,unsigned int sClientID,Client* sClient)
			:action(sAction),clientID(sClientID),client(sClient)
			{
			}
		};
	
	typedef std::vector<ClientListAction> ActionList; // Type for lists of client list actions
	
	struct ServerState // Structure containing the transient state of a collaboration server
		{
		/* Elements: */
		public:
		unsigned int numClients; // Number of remote clients connected to the server
		unsigned int* clientIDs; // Array of server-wide unique client IDs
		CollaborationPipe::ClientState* clientStates; // Array of client states
		
		/* Constructors and destructors: */
		ServerState(void); // Creates empty server state
		~ServerState(void); // Destroys a server state
		
		/* Methods: */
		void resize(unsigned int newNumClients); // Resizes the server state arrays
		};
	
	/* Elements: */
	protected:
	CollaborationPipe* pipe; // Pipe connected to the collaboration server
	Misc::ConfigurationFile configFile; // Configuration file for the collaboration client and all protocol plug-ins
	private:
	Threads::Thread communicationThread; // Thread handling communication with the collaboration server
	ProtocolList protocols; // List of protocols currently registered with the server
	std::vector<ProtocolClient*> messageTable; // Table mapping from message IDs to the protocol engines handling them
	
	/* Lists keeping track of persistent state of remote clients: */
	Threads::Mutex clientListMutex; // Mutex protecting the client list
	ClientList clientList; // The list containing the states of all currently connected clients
	ClientHash clientHash; // Hash table mapping from client IDs to client objects
	ActionList actionList; // List of recent client list actions
	
	/* States of remote clients and local clients: */
	Threads::TripleBuffer<ServerState> serverState; // Triple buffer containing updated states of remote clients
	Threads::TripleBuffer<CollaborationPipe::ClientState> localState; // Triple buffer containing transient state of local client
	int followClientIndex; // Index of client whose navigation transformation to follow (-1 if disabled)
	int faceClientIndex; // Index of client whom to face in a conversation (-1 if disabled)
	
	/* User interface: */
	GLMotif::PopupWindow* remoteClientDialogPopup; // Dialog window showing currently connected remote clients
	GLMotif::RowColumn* clientListRowColumn; // RowColumn widget containing the connected client list
	
	/* Rendering flags: */
	Vrui::Glyph viewerGlyph; // Glyph to render a remote viewer
	Vrui::Glyph inputDeviceGlyph; // Glyph to render a remote input device
	bool fixGlyphScaling; // Always keep displayed glyphs at their configured size, even when navigation scaling is different
	bool renderRemoteEnvironments; // Render the orientations and sizes of the environments of remote clients
	
	/* Private methods: */
	void* communicationThreadMethod(void); // Method for thread receiving messages from the collaboration server
	void* serverUpdateThreadMethod(void); // Method for thread sending client state updates to the collaboration server
	
	/* Constructors and destructors: */
	public:
	CollaborationClient(const char* hostname,int portId); // Opens a connection to the given collaboration server under the given display name
	private:
	CollaborationClient(const CollaborationClient& source); // Prohibit copy constructor
	CollaborationClient& operator=(const CollaborationClient& source); // Prohibit assignment operator
	public:
	virtual ~CollaborationClient(void); // Disconnects from the collaboration server
	
	/* Methods: */
	CollaborationPipe* getPipe(void) // Returns pointer to the client's collaboration pipe
		{
		return pipe;
		}
	virtual void registerProtocol(ProtocolClient* newProtocol); // Registers a new protocol with the client; must be called before connect()
	virtual void connect(const char* clientName); // Runs the connection initiation protocol; throws exception if fails
	Vrui::Glyph& getViewerGlyph(void) // Returns the glyph used to display remote viewers
		{
		return viewerGlyph;
		}
	Vrui::Glyph& getInputDeviceGlyph(void) // Returns the glyph used to display remote input devices
		{
		return inputDeviceGlyph;
		}
	void setFixGlyphScaling(bool enable); // Sets the fixed glyph scaling flag
	void setRenderRemoteEnvironments(bool enable); // Sets the remote environment rendering flag
	virtual void frame(void); // Same as frame method of Vrui applications and vislets
	virtual void display(GLContextData& contextData) const; // Same as display method of Vrui applications and vislets; needs to be called in navigation coordinates
	void followClientToggleValueChangedCallback(GLMotif::ToggleButton::ValueChangedCallbackData* cbData); // Callback method when one of the "Follow" toggles changes value
	void faceClientToggleValueChangedCallback(GLMotif::ToggleButton::ValueChangedCallbackData* cbData); // Callback method when one of the "Face" toggles changes value
	
	/*********************************************************************
	Hook methods to layer application-level protocols over the base
	protocol:
	*********************************************************************/
	
	/* Hooks to add payloads to lower-level protocol messages: */
	virtual void sendConnectRequest(void); // Hook called when the client sends a connection request message to the server
	virtual void receiveConnectReply(void); // Hook called when the client receives a positive connection reply
	virtual void receiveConnectReject(void); // Hook called when the client receives a negative connection reply
	virtual void sendDisconnectRequest(void); // Hook called when the client sends a disconnection request message to the server
	virtual void receiveDisconnectReply(void); // Hook called when the client receives a disconnection reply message from the server
	virtual void sendClientUpdate(void); // Hook called when the client sends a client state update packet
	virtual void receiveClientConnect(unsigned int clientID); // Hook called when the client receives a connection message for the given remote client
	virtual void receiveClientDisconnect(unsigned int clientID); // Hook called when the client receives a disconnection message for the given remote client
	virtual void receiveServerUpdate(void); // Hook called when the client receives a state update packet from the server
	virtual void receiveServerUpdate(unsigned int clientID); // Hook called when the client receives a state update packet for the given remote client from the server
	
	/* Hooks to insert processing into the lower-level protocol state machine: */
	virtual bool handleMessage(CollaborationPipe::MessageIdType messageId); // Hook called when the client receives unknown message from server; returns false to signal protocol error
	virtual void beforeClientUpdate(void); // Hook called right before the client sends a client update packet
	};

}

#endif
