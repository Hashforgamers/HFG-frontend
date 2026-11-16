import { readFileSync } from 'node:fs';
import { test, before, after, beforeEach } from 'node:test';
import {
  initializeTestEnvironment, assertSucceeds, assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, deleteDoc, collection, query, where, getDocs,
  arrayUnion, arrayRemove, increment, serverTimestamp, addDoc, writeBatch,
} from 'firebase/firestore';

let env;
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'hash-rules-test',
    firestore: { rules: readFileSync(process.env.RULES, 'utf8'), host: '127.0.0.1', port: 8080 },
  });
});
after(() => env.cleanup());
beforeEach(() => env.clearFirestore());

const db = (uid) => (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).firestore();
const seed = (fn) => env.withSecurityRulesDisabled((c) => fn(c.firestore()));

test('signed-out users get nothing', async () => {
  await assertFails(getDoc(doc(db(null), 'chat_users/a')));
  await assertFails(setDoc(doc(db(null), 'ludo_matches/m'), { host_uid: 'x' }));
});

test('unknown + server-only collections are closed', async () => {
  for (const c of ['users', 'reward_ledger', 'reward_state', 'push_caps', 'notification_templates', 'cafes', 'franchise_leads', 'random_new']) {
    await assertFails(getDoc(doc(db('alice'), `${c}/x`)));
    await assertFails(setDoc(doc(db('alice'), `${c}/x`), { a: 1 }));
  }
});

test('chat_users: read all, write own only', async () => {
  const a = db('alice');
  await assertSucceeds(setDoc(doc(a, 'chat_users/alice'), { uid: 'alice', is_online: true }, { merge: true }));
  await assertSucceeds(getDocs(collection(a, 'chat_users')));
  await assertFails(setDoc(doc(a, 'chat_users/bob'), { is_online: false }, { merge: true }));
});

test('chat rooms: members only, join shared rooms, leave', async () => {
  await seed((s) => setDoc(doc(s, 'chat_rooms/dm_ab'), { members: ['alice', 'bob'], admins: ['alice'] }));
  const a = db('alice'), e = db('eve');
  await assertSucceeds(getDoc(doc(a, 'chat_rooms/dm_ab')));
  await assertSucceeds(getDocs(query(collection(a, 'chat_rooms'), where('members', 'array-contains', 'alice'))));
  await assertFails(getDoc(doc(e, 'chat_rooms/dm_ab')));
  await assertFails(getDocs(collection(e, 'chat_rooms')));
  await assertFails(setDoc(doc(e, 'chat_rooms/dm_ab'), { name: 'pwned' }, { merge: true }));
  // per-user flags
  await assertSucceeds(setDoc(doc(a, 'chat_rooms/dm_ab'), { muted_uids: arrayUnion('alice') }, { merge: true }));
  // lounge join (doc may not exist yet)
  await assertSucceeds(getDoc(doc(e, 'chat_rooms/mini_games_lounge')));
  await assertSucceeds(setDoc(doc(e, 'chat_rooms/mini_games_lounge'), { members: arrayUnion('eve'), type: 'group' }, { merge: true }));
  await assertSucceeds(setDoc(doc(db('bob'), 'chat_rooms/mini_games_lounge'), { members: arrayUnion('bob') }, { merge: true }));
  // new direct room
  await assertSucceeds(setDoc(doc(a, 'chat_rooms/new1'), { members: ['alice', 'carol'] }));
  await assertFails(setDoc(doc(e, 'chat_rooms/new2'), { members: ['alice', 'carol'] }));
  // leave group: remove self
  await assertSucceeds(updateDoc(doc(db('bob'), 'chat_rooms/dm_ab'), { members: arrayRemove('bob') }));
});

test('chat messages', async () => {
  await seed(async (s) => {
    await setDoc(doc(s, 'chat_rooms/r'), { members: ['alice', 'bob'] });
    await setDoc(doc(s, 'chat_rooms/r/messages/m1'), { sender_id: 'bob', text: 'hi', seen_by: ['bob'] });
  });
  const a = db('alice');
  await assertSucceeds(getDocs(collection(a, 'chat_rooms/r/messages')));
  await assertFails(getDocs(collection(db('eve'), 'chat_rooms/r/messages')));
  const b = writeBatch(a);
  b.set(doc(a, 'chat_rooms/r/messages/m2'), { sender_id: 'alice', text: 'yo' });
  b.set(doc(a, 'chat_rooms/r'), { last_message: 'yo' }, { merge: true });
  await assertSucceeds(b.commit());
  await assertFails(setDoc(doc(a, 'chat_rooms/r/messages/m3'), { sender_id: 'bob', text: 'fake' }));
  await assertSucceeds(updateDoc(doc(a, 'chat_rooms/r/messages/m1'), { seen_by: arrayUnion('alice') }));
  await assertFails(deleteDoc(doc(a, 'chat_rooms/r/messages/m1')));
});

test('dispute rooms', async () => {
  await seed(async (s) => {
    await setDoc(doc(s, 'communityDisputeRooms/d'), { participant_firebase_uids: ['hfg-user-1'], admin_user_ids: [] });
  });
  await assertSucceeds(getDoc(doc(db('hfg-user-1'), 'communityDisputeRooms/d')));
  await assertSucceeds(setDoc(doc(db('hfg-user-1'), 'communityDisputeRooms/d/messages/x'), { sender_id: 'hfg-user-1', text: 'a' }));
  await assertFails(getDoc(doc(db('googleUid123'), 'communityDisputeRooms/d')));
  await assertFails(getDocs(collection(db('googleUid123'), 'communityDisputeRooms/d/messages')));
});

test('friendships, blocks, reports', async () => {
  const a = db('alice');
  await assertSucceeds(setDoc(doc(a, 'social_friendships/alice_bob'), { users: ['alice', 'bob'], requester_uid: 'alice', recipient_uid: 'bob', status: 'pending' }));
  await assertSucceeds(getDocs(query(collection(a, 'social_friendships'), where('users', 'array-contains', 'alice'))));
  await assertFails(getDocs(collection(db('eve'), 'social_friendships')));
  await assertSucceeds(updateDoc(doc(db('bob'), 'social_friendships/alice_bob'), { status: 'accepted' }));
  await assertFails(setDoc(doc(db('eve'), 'social_friendships/x'), { users: ['alice', 'bob'], requester_uid: 'alice' }));
  await assertSucceeds(setDoc(doc(a, 'social_blocks/alice_eve'), { blocker_uid: 'alice', blocked_uid: 'eve' }));
  await assertSucceeds(getDocs(query(collection(a, 'social_blocks'), where('blocker_uid', '==', 'alice'))));
  await assertFails(setDoc(doc(db('eve'), 'social_blocks/alice_x'), { blocker_uid: 'alice' }));
  await assertSucceeds(addDoc(collection(a, 'social_reports'), { reporter: 'alice' }));
  await assertFails(getDocs(collection(a, 'social_reports')));
});

test('live streams, hosts, followers', async () => {
  const h = db('host'), v = db('viewer');
  await assertSucceeds(setDoc(doc(h, 'live_streams/s'), { host_uid: 'host', is_live: true }));
  await assertSucceeds(setDoc(doc(h, 'live_hosts/host'), { active_stream_id: 's' }, { merge: true }));
  await assertSucceeds(setDoc(doc(v, 'live_streams/s/viewers/viewer'), { joined_at: serverTimestamp() }));
  await assertSucceeds(setDoc(doc(v, 'live_streams/s'), { viewer_count: increment(1), updated_at: serverTimestamp() }, { merge: true }));
  await assertFails(setDoc(doc(v, 'live_streams/s'), { is_live: false }, { merge: true }));
  await assertSucceeds(setDoc(doc(v, 'live_hosts/host/followers/viewer'), { followed_at: serverTimestamp() }));
  await assertSucceeds(setDoc(doc(v, 'live_hosts/host'), { followers_count: increment(1), updated_at: serverTimestamp() }, { merge: true }));
  await assertFails(setDoc(doc(v, 'live_hosts/host'), { active_stream_id: 'x' }, { merge: true }));
  await assertSucceeds(addDoc(collection(v, 'live_streams/s/messages'), { text: 'gg' }));
  await assertSucceeds(addDoc(collection(h, 'live_alerts'), { target_uid: 'viewer' }));
  await assertSucceeds(getDocs(query(collection(v, 'live_alerts'), where('target_uid', '==', 'viewer'))));
  await assertFails(getDocs(collection(v, 'live_alerts')));
});

test('leaderboards', async () => {
  const a = db('alice');
  await assertSucceeds(setDoc(doc(a, 'mini_game_leaderboard/alice'), { score: 5 }));
  await assertSucceeds(setDoc(doc(a, 'mini_game_weekly/2026-W47_alice'), { score: 5 }));
  await assertFails(setDoc(doc(a, 'mini_game_leaderboard/bob'), { score: 999 }));
  await assertFails(setDoc(doc(a, 'mini_game_weekly/2026-W47_bob'), { score: 999 }));
  await assertSucceeds(getDocs(collection(db('bob'), 'mini_game_leaderboard')));
});

test('ludo match flow incl. missed turns + spectator reaction', async () => {
  const h = db('host'), p = db('p2'), s = db('spec');
  await assertSucceeds(setDoc(doc(h, 'ludo_matches/m'), { host_uid: 'host', status: 'waiting', seats: {} }));
  await assertFails(setDoc(doc(p, 'ludo_matches/m2'), { host_uid: 'host' }));
  await assertSucceeds(updateDoc(doc(p, 'ludo_matches/m'), { 'seats.yellow': { uid: 'p2' } }));
  await assertSucceeds(updateDoc(doc(p, 'ludo_matches/m'), { 'missed.green': 1, 'missed_turn_ms.green': 123 }));
  await assertSucceeds(updateDoc(doc(s, 'ludo_matches/m'), { reaction_emoji: 'fire' }));
  await assertFails(deleteDoc(doc(h, 'ludo_matches/m')));
});

test('owned cosmetics', async () => {
  await assertSucceeds(setDoc(doc(db('alice'), 'ludo_skins/alice'), { owned: ['a'] }, { merge: true }));
  await assertSucceeds(getDoc(doc(db('alice'), 'ludo_skins/alice')));
  await assertFails(setDoc(doc(db('eve'), 'ludo_skins/alice'), { owned: [] }));
});

test('products & pre-registrations', async () => {
  await seed((s) => setDoc(doc(s, 'products/p'), { name: 'x', preRegisterCount: 3 }));
  await assertSucceeds(getDocs(collection(db('alice'), 'products')));
  await assertSucceeds(updateDoc(doc(db('alice'), 'products/p'), { preRegisterCount: increment(1) }));
  await assertFails(updateDoc(doc(db('alice'), 'products/p'), { preRegisterCount: 0 }));
  await assertFails(updateDoc(doc(db('alice'), 'products/p'), { name: 'free' }));
  await assertSucceeds(addDoc(collection(db('alice'), 'pre_registrations'), { userId: '1', productId: 'p' }));
});

test('cafe likes', async () => {
  const a = db('alice');
  const b = writeBatch(a);
  b.set(doc(a, 'cafes_external/c'), { total_likes: increment(1) }, { merge: true });
  b.set(doc(a, 'cafes_external/c/likes/k'), { firebase_uid: 'alice' });
  await assertSucceeds(b.commit());
  await assertFails(setDoc(doc(a, 'cafes_external/c/likes/k2'), { firebase_uid: 'bob' }));
});

test('bird runs, lfg, squad, funnel events', async () => {
  const a = db('alice');
  await assertSucceeds(setDoc(doc(a, 'bird_matches/b'), { host_uid: 'alice' }));
  await assertSucceeds(setDoc(doc(a, 'bird_matches/b/runs/1_alice'), { uid: 'alice' }));
  await assertFails(setDoc(doc(a, 'bird_matches/b/runs/1_bob'), { uid: 'bob' }));
  await assertSucceeds(setDoc(doc(a, 'social_lfg_posts/alice'), { is_active: true }));
  await assertSucceeds(setDoc(doc(db('bob'), 'social_lfg_posts/alice'), { member_ids: ['alice', 'bob'] }, { merge: true }));
  await assertSucceeds(setDoc(doc(a, 'squad_weekly_missions_v1/sq_w'), { missions: [] }, { merge: true }));
  await assertSucceeds(addDoc(collection(a, 'notification_funnel_events'), { e: 1 }));
  await assertFails(getDocs(collection(a, 'notification_funnel_events')));
});
