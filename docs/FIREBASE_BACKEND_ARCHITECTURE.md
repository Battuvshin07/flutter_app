# Firebase Backend Architecture

> 13th Century Mongolian History App — Backend Design Document
>
> **Stack:** Firebase Authentication (Email/Password) + Cloud Firestore + Cloud Functions (optional)

---

## Table of Contents

1. [Architecture Summary](#1-architecture-summary)
2. [Firebase Authentication](#2-firebase-authentication)
3. [Firestore Collections & Data Schema](#3-firestore-collections--data-schema)
4. [Role-Based Access Control](#4-role-based-access-control)
5. [Firestore Security Rules](#5-firestore-security-rules)
6. [Cloud Functions](#6-cloud-functions)
7. [Composite Indexes](#7-composite-indexes)
8. [Scalability & Best Practices](#8-scalability--best-practices)

---

## 1. Architecture Summary

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter Client                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ firebase_auth │  │cloud_firestore│  │   Provider   │  │
│  └──────┬───────┘  └──────┬───────┘  └──────────────┘  │
└─────────┼─────────────────┼─────────────────────────────┘
          │                 │
          ▼                 ▼
┌─────────────────────────────────────────────────────────┐
│                   Firebase Platform                     │
│                                                         │
│  ┌──────────────────┐   ┌────────────────────────────┐  │
│  │ Firebase Auth     │   │ Cloud Firestore            │  │
│  │ - Email/Password  │   │ ┌────────────────────────┐ │  │
│  │ - UID generation  │   │ │ users/{uid}            │ │  │
│  │ - Custom Claims   │◄─►│ │ persons/{docId}        │ │  │
│  └──────────────────┘   │ │ events/{docId}         │ │  │
│                          │ │ maps/{docId}           │ │  │
│  ┌──────────────────┐   │ │ quizzes/{docId}        │ │  │
│  │ Cloud Functions   │   │ │ culture/{docId}        │ │  │
│  │ - setAdminClaim() │   │ │ user_progress/{uid}/…  │ │  │
│  │ - onUserCreate()  │   │ │ favorites/{uid}/…      │ │  │
│  └──────────────────┘   │ └────────────────────────┘ │  │
│                          └────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Design principles

| Principle | Implementation |
|---|---|
| **Denormalized reads** | Each collection is self-contained; no JOINs needed |
| **Role gate** | Firebase Custom Claims (`admin: true`) checked in Security Rules |
| **Offline-first** | Firestore SDK handles local cache automatically |
| **Atomic IDs** | Content docs use string IDs matching existing `person_id`, `event_id`, etc. |
| **Timestamps** | Every document carries `createdAt` / `updatedAt` server timestamps |

---

## 2. Firebase Authentication

### Provider: Email / Password

| Setting | Value |
|---|---|
| Sign-in method | Email / Password (enabled) |
| Email enumeration protection | Enabled |
| Password policy | Min 8 chars (enforced client-side) |

### Auth flow

```
1. User signs up  →  FirebaseAuth.createUserWithEmailAndPassword()
2. Cloud Function trigger (onCreate)  →  creates /users/{uid} doc with role: "user"
3. User signs in  →  FirebaseAuth.signInWithEmailAndPassword()
4. Client reads ID token  →  token.claims.role checked for admin UI
```

### Custom Claims (set via Cloud Function)

```json
{
  "role": "admin"
}
```

The client retrieves claims via:
```dart
final idTokenResult = await FirebaseAuth.instance.currentUser!.getIdTokenResult();
final role = idTokenResult.claims?['role'] ?? 'user';
```

---

## 3. Firestore Collections & Data Schema

### 3.1 `users` — User profiles

**Path:** `users/{uid}`

| Field | Type | Required | Description |
|---|---|---|---|
| `uid` | `string` | ✅ | Firebase Auth UID (matches document ID) |
| `name` | `string` | ✅ | Display name |
| `email` | `string` | ✅ | Email address |
| `role` | `string` | ✅ | `"admin"` or `"user"` |
| `isActive` | `boolean` | ✅ | Account active flag (default `true`) |
| `avatarUrl` | `string` | — | Profile image URL |
| `lastLogin` | `timestamp` | — | Last sign-in timestamp |
| `createdAt` | `timestamp` | ✅ | Account creation time |
| `updatedAt` | `timestamp` | ✅ | Last profile update |

**Example document:**

```json
// users/abc123uid
{
  "uid": "abc123uid",
  "name": "Батбаяр",
  "email": "batbayar@example.com",
  "role": "user",
  "isActive": true,
  "avatarUrl": "",
  "lastLogin": "2026-02-28T10:00:00Z",  // Timestamp
  "createdAt": "2026-01-15T08:30:00Z",  // Timestamp
  "updatedAt": "2026-02-28T10:00:00Z"   // Timestamp
}
```

---

### 3.2 `persons` — Historical figures

**Path:** `persons/{docId}`

| Field | Type | Required | Description |
|---|---|---|---|
| `person_id` | `number` | ✅ | Legacy integer ID (for backward compat) |
| `name` | `string` | ✅ | Name of the historical figure |
| `birth_date` | `string` | — | Birth year/date |
| `death_date` | `string` | — | Death year/date |
| `description` | `string` | ✅ | Biography text |
| `image_url` | `string` | — | Asset path or remote URL |
| `createdAt` | `timestamp` | ✅ | Server timestamp |
| `updatedAt` | `timestamp` | ✅ | Server timestamp |

**Example document:**

```json
// persons/person_1
{
  "person_id": 1,
  "name": "Чингис хаан",
  "birth_date": "1162",
  "death_date": "1227",
  "description": "Их Монгол Улсын үндэслэгч...",
  "image_url": "assets/images/pic_1.png",
  "createdAt": "2026-01-01T00:00:00Z",
  "updatedAt": "2026-01-01T00:00:00Z"
}
```

**Document ID strategy:** Use `person_{person_id}` (e.g. `person_1`) so IDs are predictable and cross-referenceable.

---

### 3.3 `events` — Historical events

**Path:** `events/{docId}`

| Field | Type | Required | Description |
|---|---|---|---|
| `event_id` | `number` | ✅ | Legacy integer ID |
| `title` | `string` | ✅ | Event title |
| `date` | `string` | ✅ | Year or year range (e.g. `"1206"`, `"1219-1221"`) |
| `description` | `string` | ✅ | Event description |
| `person_id` | `number` | — | Related person's legacy ID |
| `person_ref` | `string` | — | Firestore path: `persons/person_1` (for easy lookup) |
| `createdAt` | `timestamp` | ✅ | Server timestamp |
| `updatedAt` | `timestamp` | ✅ | Server timestamp |

**Example document:**

```json
// events/event_3
{
  "event_id": 3,
  "title": "Чингис хаан цолыг хүлээн авсан",
  "date": "1206",
  "description": "Их хурилтайд Тэмүжин 'Чингис хаан' цолыг хүлээн авч...",
  "person_id": 1,
  "person_ref": "persons/person_1",
  "createdAt": "2026-01-01T00:00:00Z",
  "updatedAt": "2026-01-01T00:00:00Z"
}
```

---

### 3.4 `maps` — Geographic/territorial data

**Path:** `maps/{docId}`

| Field | Type | Required | Description |
|---|---|---|---|
| `map_id` | `number` | ✅ | Legacy integer ID |
| `title` | `string` | ✅ | Location/campaign name |
| `coordinates` | `string` | ✅ | `"lat,lon"` format |
| `geopoint` | `geopoint` | — | Firestore GeoPoint (for geo-queries) |
| `event_id` | `number` | — | Related event's legacy ID |
| `event_ref` | `string` | — | Firestore path: `events/event_3` |
| `description` | `string` | — | Location description |
| `year` | `string` | — | Year or year range |
| `color` | `string` | — | Hex color `"0xFF8B4513"` |
| `createdAt` | `timestamp` | ✅ | Server timestamp |
| `updatedAt` | `timestamp` | ✅ | Server timestamp |

**Example document:**

```json
// maps/map_1
{
  "map_id": 1,
  "title": "Монгол нутаг - Эх орон",
  "coordinates": "47.9,106.9",
  "geopoint": { "latitude": 47.9, "longitude": 106.9 },
  "event_id": 3,
  "event_ref": "events/event_3",
  "description": "Их Монгол Улсын төв нутаг...",
  "year": "1206",
  "color": "0xFF8B4513",
  "createdAt": "2026-01-01T00:00:00Z",
  "updatedAt": "2026-01-01T00:00:00Z"
}
```

---

### 3.5 `quizzes` — Quiz questions

**Path:** `quizzes/{docId}`

| Field | Type | Required | Description |
|---|---|---|---|
| `quiz_id` | `number` | ✅ | Legacy integer ID |
| `question` | `string` | ✅ | Question text |
| `answers` | `array<string>` | ✅ | Array of answer strings (4 options) |
| `correct_answer` | `number` | ✅ | 0-based index of correct answer |
| `difficulty` | `string` | — | `"easy"`, `"medium"`, `"hard"` |
| `category` | `string` | — | Topic category for filtering |
| `createdAt` | `timestamp` | ✅ | Server timestamp |
| `updatedAt` | `timestamp` | ✅ | Server timestamp |

> **Note:** The existing Flutter model stores `answers` as a JSON-encoded string. In Firestore, store it as a native `array<string>` for better query support.

**Example document:**

```json
// quizzes/quiz_1
{
  "quiz_id": 1,
  "question": "Чингис хаан хэдэн онд төрсөн бэ?",
  "answers": ["1155", "1162", "1170", "1180"],
  "correct_answer": 1,
  "difficulty": "easy",
  "category": "persons",
  "createdAt": "2026-01-01T00:00:00Z",
  "updatedAt": "2026-01-01T00:00:00Z"
}
```

---

### 3.6 `culture` — Cultural topics

**Path:** `culture/{docId}`

| Field | Type | Required | Description |
|---|---|---|---|
| `culture_id` | `number` | ✅ | Legacy integer ID |
| `title` | `string` | ✅ | Topic title |
| `icon` | `string` | — | Material icon name |
| `description` | `string` | ✅ | Short summary |
| `details` | `string` | ✅ | Full article text |
| `createdAt` | `timestamp` | ✅ | Server timestamp |
| `updatedAt` | `timestamp` | ✅ | Server timestamp |

**Example document:**

```json
// culture/culture_1
{
  "culture_id": 1,
  "title": "Нүүдлийн соёл",
  "icon": "landscape",
  "description": "Монголчууд нүүдлийн амьдралын хэв маягтай байсан...",
  "details": "Монголчуудын нүүдлийн соёл нь мянга мянган жилийн түүхтэй...",
  "createdAt": "2026-01-01T00:00:00Z",
  "updatedAt": "2026-01-01T00:00:00Z"
}
```

---

### 3.7 `user_progress` — Per-user quiz/learning progress (optional)

**Path:** `user_progress/{uid}/quizzes/{quizDocId}`

| Field | Type | Required | Description |
|---|---|---|---|
| `quiz_id` | `number` | ✅ | Quiz legacy ID |
| `score` | `number` | ✅ | User's score (0-100) |
| `completed` | `boolean` | ✅ | Whether finished |
| `attempts` | `number` | ✅ | Number of attempts |
| `lastAttemptAt` | `timestamp` | ✅ | Last attempt time |
| `selectedAnswer` | `number` | — | Last selected answer index |

**Example document:**

```json
// user_progress/abc123uid/quizzes/quiz_1
{
  "quiz_id": 1,
  "score": 100,
  "completed": true,
  "attempts": 2,
  "lastAttemptAt": "2026-02-28T09:00:00Z",
  "selectedAnswer": 1
}
```

**Path:** `user_progress/{uid}/summary`

Single aggregated document for quick dashboard reads:

```json
// user_progress/abc123uid/summary/stats
{
  "totalXp": 1250,
  "quizzesCompleted": 8,
  "quizzesTotal": 10,
  "averageScore": 85,
  "streak": 5,
  "lastActiveAt": "2026-02-28T09:00:00Z"
}
```

---

### 3.8 `favorites` — User bookmarked content (optional)

**Path:** `favorites/{uid}/items/{docId}`

| Field | Type | Required | Description |
|---|---|---|---|
| `contentType` | `string` | ✅ | `"person"`, `"event"`, `"culture"`, `"map"` |
| `contentId` | `string` | ✅ | Reference doc ID (e.g. `"person_1"`) |
| `title` | `string` | ✅ | Denormalized title for fast list display |
| `addedAt` | `timestamp` | ✅ | When bookmarked |

**Example document:**

```json
// favorites/abc123uid/items/person_1
{
  "contentType": "person",
  "contentId": "person_1",
  "title": "Чингис хаан",
  "addedAt": "2026-02-20T14:00:00Z"
}
```

---

### 3.9 `reading_history` — Recently viewed content (optional)

**Path:** `reading_history/{uid}/entries/{autoId}`

| Field | Type | Required | Description |
|---|---|---|---|
| `contentType` | `string` | ✅ | `"person"`, `"event"`, `"culture"`, `"map"` |
| `contentId` | `string` | ✅ | Content doc ID |
| `title` | `string` | ✅ | Denormalized title |
| `viewedAt` | `timestamp` | ✅ | When viewed |

---

### Collection Map (visual summary)

```
Firestore Root
│
├── users/{uid}                          ← profile + role
│
├── persons/{docId}                      ← historical figures
├── events/{docId}                       ← historical events
├── maps/{docId}                         ← geographic data
├── quizzes/{docId}                      ← quiz questions
├── culture/{docId}                      ← cultural topics
│
├── user_progress/{uid}/                 ← per-user data (subcollection)
│   ├── quizzes/{quizDocId}
│   └── summary/stats
│
├── favorites/{uid}/                     ← per-user bookmarks (subcollection)
│   └── items/{docId}
│
└── reading_history/{uid}/               ← per-user view history (subcollection)
    └── entries/{autoId}
```

---

## 4. Role-Based Access Control

### Approach comparison

| Criteria | A) Firestore `users/{uid}.role` | B) Firebase Custom Claims ✅ |
|---|---|---|
| Where role is stored | Firestore document field | Auth token (JWT claim) |
| Checked in Security Rules | `get(/databases/…/users/$(uid)).data.role` | `request.auth.token.role` |
| Read cost per request | 1 extra Firestore read per rule check | Zero (embedded in token) |
| Latency | Slower (document read) | Faster (already in token) |
| Max data | Unlimited | 1000 bytes total claims |
| Propagation | Instant (on next read) | After token refresh (~1 hr or force refresh) |
| Security | Vulnerable if user doc is writable | Cannot be set client-side |
| Who can set | Anyone with write access to the doc | Only server / Cloud Functions |

### ✅ Recommended: Hybrid approach (B with A as mirror)

1. **Custom Claims** (primary) — Used in Security Rules for zero-cost role checks.
2. **Firestore `users/{uid}.role`** (mirror) — Used by client UI to display role without decoding token, and by admin dashboards for user management queries.

**How it works:**

```
Admin (via Cloud Function)
    │
    ├─► auth.setCustomUserClaims(uid, { role: "admin" })   ← token source of truth
    │
    └─► firestore.doc("users/${uid}").update({ role: "admin" })  ← mirror for queries
```

**Client: check role**

```dart
// Option 1: From token (authoritative)
final tokenResult = await user.getIdTokenResult(true); // force refresh
final isAdmin = tokenResult.claims?['role'] == 'admin';

// Option 2: From Firestore doc (for UI display)
final doc = await FirebaseFirestore.instance.doc('users/${user.uid}').get();
final role = doc.data()?['role'] ?? 'user';
```

---

## 5. Firestore Security Rules

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // ═══════════════════════════════════════
    // Helper functions
    // ═══════════════════════════════════════

    /// Check if the request is from an authenticated user
    function isAuthenticated() {
      return request.auth != null;
    }

    /// Check if the authenticated user is an admin (via Custom Claims)
    function isAdmin() {
      return isAuthenticated() && request.auth.token.role == 'admin';
    }

    /// Check if the authenticated user owns this document
    function isOwner(uid) {
      return isAuthenticated() && request.auth.uid == uid;
    }

    /// Validate that a timestamp field is a server timestamp
    function isValidTimestamp(field) {
      return field is timestamp;
    }

    /// Validate that a string field is non-empty and within max length
    function isNonEmptyString(val, maxLen) {
      return val is string && val.size() > 0 && val.size() <= maxLen;
    }

    // ═══════════════════════════════════════
    // users/{uid} — User profiles
    // ═══════════════════════════════════════
    match /users/{uid} {
      // Any authenticated user can read any user profile
      // (needed for admin dashboard user list)
      allow read: if isAuthenticated();

      // Users can create their own profile doc on signup
      allow create: if isOwner(uid)
                    && request.resource.data.role == 'user'    // cannot self-assign admin
                    && isNonEmptyString(request.resource.data.name, 100)
                    && isNonEmptyString(request.resource.data.email, 320);

      // Users can update their own profile (but NOT the role field)
      allow update: if isOwner(uid)
                    && !('role' in request.resource.data
                         && request.resource.data.role != resource.data.role)
                    // Alternatively: role field must stay the same
                    && request.resource.data.role == resource.data.role;

      // Admins can update any user profile (including role, isActive)
      allow update: if isAdmin();

      // Only admins can delete user profiles
      allow delete: if isAdmin();
    }

    // ═══════════════════════════════════════
    // persons/{docId} — Historical figures
    // ═══════════════════════════════════════
    match /persons/{docId} {
      // Any authenticated user can read
      allow read: if isAuthenticated();

      // Only admins can create, update, delete
      allow create: if isAdmin()
                    && isNonEmptyString(request.resource.data.name, 200)
                    && isNonEmptyString(request.resource.data.description, 10000);

      allow update: if isAdmin();
      allow delete: if isAdmin();
    }

    // ═══════════════════════════════════════
    // events/{docId} — Historical events
    // ═══════════════════════════════════════
    match /events/{docId} {
      allow read: if isAuthenticated();

      allow create: if isAdmin()
                    && isNonEmptyString(request.resource.data.title, 300)
                    && isNonEmptyString(request.resource.data.date, 50)
                    && isNonEmptyString(request.resource.data.description, 10000);

      allow update: if isAdmin();
      allow delete: if isAdmin();
    }

    // ═══════════════════════════════════════
    // maps/{docId} — Geographic data
    // ═══════════════════════════════════════
    match /maps/{docId} {
      allow read: if isAuthenticated();

      allow create: if isAdmin()
                    && isNonEmptyString(request.resource.data.title, 300)
                    && isNonEmptyString(request.resource.data.coordinates, 50);

      allow update: if isAdmin();
      allow delete: if isAdmin();
    }

    // ═══════════════════════════════════════
    // quizzes/{docId} — Quiz questions
    // ═══════════════════════════════════════
    match /quizzes/{docId} {
      allow read: if isAuthenticated();

      allow create: if isAdmin()
                    && isNonEmptyString(request.resource.data.question, 1000)
                    && request.resource.data.answers is list
                    && request.resource.data.answers.size() >= 2
                    && request.resource.data.correct_answer is int
                    && request.resource.data.correct_answer >= 0
                    && request.resource.data.correct_answer < request.resource.data.answers.size();

      allow update: if isAdmin();
      allow delete: if isAdmin();
    }

    // ═══════════════════════════════════════
    // culture/{docId} — Cultural topics
    // ═══════════════════════════════════════
    match /culture/{docId} {
      allow read: if isAuthenticated();

      allow create: if isAdmin()
                    && isNonEmptyString(request.resource.data.title, 300)
                    && isNonEmptyString(request.resource.data.description, 10000);

      allow update: if isAdmin();
      allow delete: if isAdmin();
    }

    // ═══════════════════════════════════════
    // user_progress/{uid}/** — Per-user progress
    // ═══════════════════════════════════════
    match /user_progress/{uid}/{document=**} {
      // Users can only read/write their own progress
      allow read, write: if isOwner(uid);

      // Admins can read any user's progress (for analytics)
      allow read: if isAdmin();
    }

    // ═══════════════════════════════════════
    // favorites/{uid}/** — User bookmarks
    // ═══════════════════════════════════════
    match /favorites/{uid}/{document=**} {
      // Users can only read/write their own favorites
      allow read, write: if isOwner(uid);

      // Admins can read for analytics
      allow read: if isAdmin();
    }

    // ═══════════════════════════════════════
    // reading_history/{uid}/** — View history
    // ═══════════════════════════════════════
    match /reading_history/{uid}/{document=**} {
      // Users can only read/write their own history
      allow read, write: if isOwner(uid);

      // Admins can read for analytics
      allow read: if isAdmin();
    }
  }
}
```

---

## 6. Cloud Functions

### 6.1 Auto-create user profile on signup

Trigger: `auth.user().onCreate`

```typescript
// functions/src/index.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

/**
 * When a new user signs up via Firebase Auth,
 * automatically create their Firestore profile document
 * with role: "user".
 */
export const onUserCreated = functions.auth.user().onCreate(async (user) => {
  const { uid, email, displayName } = user;

  await db.doc(`users/${uid}`).set({
    uid,
    name: displayName || '',
    email: email || '',
    role: 'user',
    isActive: true,
    avatarUrl: '',
    lastLogin: admin.firestore.FieldValue.serverTimestamp(),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Set default custom claim
  await admin.auth().setCustomUserClaims(uid, { role: 'user' });

  console.log(`Created user profile for ${uid} (${email})`);
});
```

---

### 6.2 Set admin role (callable function)

Only an existing admin can promote another user to admin.

```typescript
/**
 * Callable function to assign admin role to a user.
 * Can only be called by an existing admin.
 *
 * Client call:
 *   final callable = FirebaseFunctions.instance.httpsCallable('setAdminRole');
 *   await callable.call({ 'targetUid': 'someUserId', 'role': 'admin' });
 */
export const setAdminRole = functions.https.onCall(async (data, context) => {
  // 1. Verify caller is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Must be signed in.'
    );
  }

  // 2. Verify caller is an admin
  const callerClaims = context.auth.token;
  if (callerClaims.role !== 'admin') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can assign roles.'
    );
  }

  // 3. Validate input
  const { targetUid, role } = data;
  if (!targetUid || typeof targetUid !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'targetUid is required.'
    );
  }
  if (!['admin', 'user'].includes(role)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'role must be "admin" or "user".'
    );
  }

  // 4. Prevent removing the last admin
  if (role === 'user') {
    const adminsSnapshot = await db
      .collection('users')
      .where('role', '==', 'admin')
      .get();
    if (adminsSnapshot.size <= 1) {
      const isTarget = adminsSnapshot.docs.some((d) => d.id === targetUid);
      if (isTarget) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Cannot remove the last admin.'
        );
      }
    }
  }

  // 5. Set custom claims on Auth token
  await admin.auth().setCustomUserClaims(targetUid, { role });

  // 6. Mirror role in Firestore user doc
  await db.doc(`users/${targetUid}`).update({
    role,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`Role for ${targetUid} set to "${role}" by ${context.auth.uid}`);

  return { success: true, message: `Role updated to ${role}` };
});
```

---

### 6.3 Suspend / delete user (callable function)

```typescript
/**
 * Callable function to suspend or delete a user.
 * Admin-only.
 */
export const manageUser = functions.https.onCall(async (data, context) => {
  if (!context.auth || context.auth.token.role !== 'admin') {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Admin access required.'
    );
  }

  const { targetUid, action } = data; // action: 'suspend' | 'activate' | 'delete'

  if (!targetUid || !['suspend', 'activate', 'delete'].includes(action)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'targetUid and valid action required.'
    );
  }

  // Prevent self-action
  if (targetUid === context.auth.uid) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Cannot perform this action on yourself.'
    );
  }

  switch (action) {
    case 'suspend':
      await admin.auth().updateUser(targetUid, { disabled: true });
      await db.doc(`users/${targetUid}`).update({
        isActive: false,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      break;

    case 'activate':
      await admin.auth().updateUser(targetUid, { disabled: false });
      await db.doc(`users/${targetUid}`).update({
        isActive: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      break;

    case 'delete':
      await admin.auth().deleteUser(targetUid);
      await db.doc(`users/${targetUid}`).delete();
      // Optionally delete subcollections
      const batch = db.batch();
      const progressDocs = await db.collection(`user_progress/${targetUid}/quizzes`).get();
      progressDocs.forEach((doc) => batch.delete(doc.ref));
      const favDocs = await db.collection(`favorites/${targetUid}/items`).get();
      favDocs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
      break;
  }

  return { success: true, message: `User ${action}d successfully.` };
});
```

---

### 6.4 Seed initial admin (one-time setup)

Run this once via Firebase CLI or a one-time Cloud Function:

```typescript
/**
 * One-time HTTP function to bootstrap the first admin.
 * Deploy, call once, then delete or disable.
 *
 * curl https://<region>-<project>.cloudfunctions.net/seedAdmin?email=admin@example.com
 */
export const seedAdmin = functions.https.onRequest(async (req, res) => {
  const email = req.query.email as string;
  if (!email) {
    res.status(400).send('email query param required');
    return;
  }

  try {
    const user = await admin.auth().getUserByEmail(email);

    await admin.auth().setCustomUserClaims(user.uid, { role: 'admin' });
    await db.doc(`users/${user.uid}`).update({
      role: 'admin',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.send(`${email} is now admin (uid: ${user.uid}). Delete this function!`);
  } catch (error: any) {
    res.status(500).send(`Error: ${error.message}`);
  }
});
```

---

## 7. Composite Indexes

Firestore auto-creates single-field indexes. You need composite indexes for multi-field queries.

### `firestore.indexes.json`

```json
{
  "indexes": [
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "role", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "lastLogin", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "events",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "person_id", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "maps",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "event_id", "order": "ASCENDING" },
        { "fieldPath": "year", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "quizzes",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "difficulty", "order": "ASCENDING" },
        { "fieldPath": "category", "order": "ASCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

Deploy with:
```bash
firebase deploy --only firestore:indexes
```

---

## 8. Scalability & Best Practices

### Document size & reads

| Guideline | Detail |
|---|---|
| **Max document size** | 1 MiB — keep `description`/`details` under control |
| **Avoid unbounded arrays** | `answers` array (4 items) is fine; don't store thousands of items in an array |
| **Denormalize for reads** | Store `title` inside `favorites` so you don't need a second read |
| **Use subcollections** | `user_progress/{uid}/quizzes/…` instead of a giant nested map |

### Timestamps

Always use server timestamps for consistency:

```dart
// Dart / Flutter
import 'package:cloud_firestore/cloud_firestore.dart';

await docRef.set({
  'title': 'Чингис хаан',
  'createdAt': FieldValue.serverTimestamp(),
  'updatedAt': FieldValue.serverTimestamp(),
});
```

### Batched writes for seeding

When migrating from JSON assets to Firestore, use batched writes (max 500 ops per batch):

```dart
final batch = FirebaseFirestore.instance.batch();
for (final person in persons) {
  final ref = FirebaseFirestore.instance.doc('persons/person_${person.personId}');
  batch.set(ref, {
    ...person.toMap(),
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
await batch.commit();
```

### Offline support

Firestore SDK caches data locally by default. For explicit control:

```dart
// Enable offline persistence (enabled by default on mobile)
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

### Security rules testing

Test rules before deploying using the Firebase Emulator Suite:

```bash
firebase emulators:start --only firestore
# Then run rule unit tests
firebase emulators:exec --only firestore "npm test"
```

### Cost optimization

| Strategy | Benefit |
|---|---|
| Cache content collections client-side | Content rarely changes; read once, cache |
| Use `.get({ source: Source.cache })` for repeat reads | Avoids billable reads |
| Paginate user lists (20 per page) | Bounded reads |
| Aggregate progress in `summary/stats` doc | 1 read instead of N |

### Migration checklist

- [ ] Enable Email/Password auth in Firebase Console
- [ ] Deploy Firestore Security Rules
- [ ] Deploy composite indexes
- [ ] Deploy Cloud Functions (`onUserCreated`, `setAdminRole`, `manageUser`)
- [ ] Seed content from JSON assets to Firestore (one-time batch write)
- [ ] Run `seedAdmin` to promote the first admin account
- [ ] Delete `seedAdmin` function after use
- [ ] Test all rules with Firebase Emulator Suite

---

## Quick Reference: Dart Client Patterns

### Check admin role

```dart
Future<bool> isCurrentUserAdmin() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;
  final token = await user.getIdTokenResult(true);
  return token.claims?['role'] == 'admin';
}
```

### Read content (any authenticated user)

```dart
Stream<List<Person>> getPersons() {
  return FirebaseFirestore.instance
      .collection('persons')
      .orderBy('person_id')
      .snapshots()
      .map((snap) => snap.docs.map((d) => Person.fromMap(d.data())).toList());
}
```

### Admin: create content

```dart
Future<void> createPerson(Person person) async {
  final ref = FirebaseFirestore.instance.doc('persons/person_${person.personId}');
  await ref.set({
    ...person.toMap(),
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
```

### Admin: assign role via Cloud Function

```dart
Future<void> setUserRole(String targetUid, String role) async {
  final callable = FirebaseFunctions.instance.httpsCallable('setAdminRole');
  await callable.call({'targetUid': targetUid, 'role': role});
}
```
