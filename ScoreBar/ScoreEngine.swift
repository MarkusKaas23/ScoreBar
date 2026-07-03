import Foundation
import MultipeerConnectivity
import Observation

@Observable
class ScoreEngine: NSObject {

    // MARK: - State
    var markusScore: Int = 0
    var marcusScore: Int = 0
    var isConnected: Bool = false
    var connectedPeerName: String = ""

    // MARK: - Multipeer
    private let serviceType = "foos-score"
    private let myPeerID:   MCPeerID
    private var session:    MCSession!
    private var advertiser: MCNearbyServiceAdvertiser!
    private var browser:    MCNearbyServiceBrowser!

    // MARK: - Init
    override init() {
        let name = Host.current().localizedName ?? "Mac"
        myPeerID = MCPeerID(displayName: name)
        super.init()

        markusScore = UserDefaults.standard.integer(forKey: "sb_markus")
        marcusScore = UserDefaults.standard.integer(forKey: "sb_marcus")

        session          = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .none)
        session.delegate = self

        advertiser          = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()

        browser          = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser.delegate = self
        browser.startBrowsingForPeers()
    }

    // MARK: - Score actions
    func incrementMarkus() { markusScore += 1;                      persist(); broadcast() }
    func decrementMarkus() { markusScore = max(0, markusScore - 1); persist(); broadcast() }
    func incrementMarcus() { marcusScore += 1;                      persist(); broadcast() }
    func decrementMarcus() { marcusScore = max(0, marcusScore - 1); persist(); broadcast() }
    func reset()           { markusScore = 0; marcusScore = 0;      persist(); broadcast() }

    // MARK: - Helpers
    private func persist() {
        UserDefaults.standard.set(markusScore, forKey: "sb_markus")
        UserDefaults.standard.set(marcusScore, forKey: "sb_marcus")
    }

    private func broadcast() {
        guard !session.connectedPeers.isEmpty else { return }
        let packet = ScorePacket(markus: markusScore, marcus: marcusScore)
        guard let data = try? JSONEncoder().encode(packet) else { return }
        try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
    }
}

// MARK: - Packet
private struct ScorePacket: Codable {
    let markus: Int
    let marcus: Int
}

// MARK: - MCSessionDelegate
extension ScoreEngine: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            self.isConnected       = !session.connectedPeers.isEmpty
            self.connectedPeerName = session.connectedPeers.first?.displayName ?? ""
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let packet = try? JSONDecoder().decode(ScorePacket.self, from: data) else { return }
        Task { @MainActor in
            self.markusScore = packet.markus
            self.marcusScore = packet.marcus
            self.persist()
        }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension ScoreEngine: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension ScoreEngine: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
}
