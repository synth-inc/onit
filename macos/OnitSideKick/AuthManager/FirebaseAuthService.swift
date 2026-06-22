//
//  FirebaseAuthService.swift
//  Onit
//
//  Created by Kévin Naudin on 2026-04-30.
//

import FirebaseAuth
import Foundation

/// Bridges the onit-server JWT session to Firebase Auth by exchanging it for a custom token.
/// The resulting Firebase user has a UID equal to the onit `accountId`, which Security Rules
/// rely on to gate access to per-user Firestore documents and Storage objects.
@MainActor
final class FirebaseAuthService {

    static let shared = FirebaseAuthService()

    private init() {}

    private(set) var isSignedIn: Bool = false

    /// Tracks the in-flight sign-in task so `signOut()` can cancel it. Without
    /// this, a logout immediately followed by a re-login as another account
    /// could see the previous (now stale) sign-in resume after `signOut`,
    /// resurrecting the old UID in `Auth.auth().currentUser`.
    private var inFlightTask: Task<Void, Never>?

    /// Mints a Firebase custom token from onit-server and signs the user into Firebase Auth.
    /// Safe to call repeatedly — if already signed in for the same UID, this is a no-op.
    /// Calling again while a previous sign-in is still in flight cancels the prior task.
    func signIn() {
        inFlightTask?.cancel()
        inFlightTask = Task { [weak self] in
            await self?.performSignIn()
        }
    }

    private func performSignIn() async {
        guard let accountId = AuthManager.shared.account?.id else {
            log.warning("[FirebaseAuthService] signIn skipped: no onit account")
            return
        }

        let expectedUid = String(accountId)

        // Cached session: re-confirm the UID matches our onit account before
        // trusting `Auth.auth().currentUser`. A user could have signed out of
        // onit (`AuthManager`) without signOut() being plumbed through to
        // Firebase — in that case the previous Firebase session must NOT be
        // reused for the new account. Always kick `retryPending()` so a cold
        // launch with a valid cached session still drains any pending uploads
        // that the previous run couldn't push (network drop, app quit
        // mid-upload, etc.) — the previous early-return was the I3 bug.
        if let current = Auth.auth().currentUser, current.uid == expectedUid {
            isSignedIn = true
            return
        }

        // If we get here with a cached `currentUser` for a DIFFERENT uid,
        // we have to clear it before signing in as the right account — the
        // signIn(withCustomToken:) call below would land on top of the
        // wrong session otherwise.
        if let current = Auth.auth().currentUser, current.uid != expectedUid {
            try? Auth.auth().signOut()
        }

        do {
            let response = try await FetchingClient().fetchFirebaseToken()
            if Task.isCancelled { return }
            try await Auth.auth().signIn(withCustomToken: response.token)
            if Task.isCancelled { return }

            // Defense-in-depth assertion: even with a correctly issued token,
            // a server bug, replay, or token leak could land us on the wrong
            // uid. The downstream uploader uses `currentUser.uid` as the
            // owning account for every doc it writes, so a mismatch here
            // would silently route uploads under the wrong identity. Bail
            // out and sign back out if so.
            guard let signedInUid = Auth.auth().currentUser?.uid, signedInUid == expectedUid else {
                let actualUid = Auth.auth().currentUser?.uid ?? "<nil>"
                log.error("[FirebaseAuthService] Post-signIn uid mismatch: expected \(expectedUid), got \(actualUid). Signing out.")
                try? Auth.auth().signOut()
                isSignedIn = false
                return
            }

            isSignedIn = true
            log.info("[FirebaseAuthService] Signed into Firebase as \(expectedUid)")
        } catch {
            isSignedIn = false
            log.error("[FirebaseAuthService] Sign-in failed: \(error)")
        }
    }

    /// Signs the user out of Firebase. Called from AuthManager.logout().
    func signOut() {
        inFlightTask?.cancel()
        inFlightTask = nil
        do {
            try Auth.auth().signOut()
            isSignedIn = false
            log.info("[FirebaseAuthService] Signed out of Firebase")
        } catch {
            log.error("[FirebaseAuthService] Sign-out failed: \(error)")
        }
    }
}
