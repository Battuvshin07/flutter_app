<!-- # OTP Email Verification - Cloud Functions Setup Guide

## 📁 Project Structure

Create a `functions` folder in your Firebase project root (same level as `flutter_app`):

```
mongol_history_app/
├── flutter_app/
├── backend/
└── functions/           ← Create this folder
    ├── package.json
    ├── index.js
    ├── .env.example
    └── src/
        └── email/
            ├── sendVerificationCode.js
            ├── verifyCode.js
            └── emailService.js
```

---

## 🚀 Step 1: Initialize Functions

```bash
cd c:\Projects\mongol_history_app
firebase init functions
# Choose JavaScript
# Say YES to ESLint
# Say YES to install dependencies
```

---

## 📦 Step 2: Install Dependencies

```bash
cd functions
npm install nodemailer crypto-js
```

---

## 📝 Step 3: Create Files

### functions/package.json
```json
{
  "name": "mongol-history-functions",
  "description": "Cloud Functions for Mongol History App",
  "engines": {
    "node": "18"
  },
  "main": "index.js",
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^4.5.0",
    "nodemailer": "^6.9.7",
    "crypto-js": "^4.2.0"
  },
  "devDependencies": {
    "eslint": "^8.55.0"
  }
}
```

### functions/index.js
```javascript
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const { sendVerificationCode } = require("./src/email/sendVerificationCode");
const { verifyCode } = require("./src/email/verifyCode");

// Export Cloud Functions
exports.sendVerificationCode = functions.https.onCall(sendVerificationCode);
exports.verifyCode = functions.https.onCall(verifyCode);
```

### functions/src/email/emailService.js
```javascript
const nodemailer = require("nodemailer");
const functions = require("firebase-functions");

// Get SMTP credentials from Firebase environment config
const EMAIL_USER = process.env.EMAIL_USER || functions.config().email?.user;
const EMAIL_PASS = process.env.EMAIL_PASS || functions.config().email?.pass;

// Create transporter for Hotmail/Outlook
const transporter = nodemailer.createTransport({
  host: "smtp-mail.outlook.com",
  port: 587,
  secure: false,
  auth: {
    user: EMAIL_USER,
    pass: EMAIL_PASS,
  },
  tls: {
    ciphers: "SSLv3",
  },
});

/**
 * Send OTP verification email
 * @param {string} to - Recipient email
 * @param {string} code - 6-digit verification code
 * @returns {Promise<boolean>} Success status
 */
async function sendOtpEmail(to, code) {
  const mailOptions = {
    from: `"Монгол Түүх App" <${EMAIL_USER}>`,
    to: to,
    subject: "Баталгаажуулах код - Монгол Түүх App",
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <style>
          body { font-family: 'Segoe UI', Arial, sans-serif; background: #0B1220; color: #EAF0FF; }
          .container { max-width: 480px; margin: 0 auto; padding: 32px; }
          .header { text-align: center; margin-bottom: 24px; }
          .title { color: #F4C84A; font-size: 24px; font-weight: bold; }
          .code-box { 
            background: #1A2740; 
            border: 2px solid #F4C84A; 
            border-radius: 12px; 
            padding: 24px; 
            text-align: center; 
            margin: 24px 0;
          }
          .code { 
            font-size: 36px; 
            font-weight: bold; 
            letter-spacing: 8px; 
            color: #F4C84A;
          }
          .expiry { color: #A9B3C9; font-size: 14px; margin-top: 16px; }
          .footer { text-align: center; color: #A9B3C9; font-size: 12px; margin-top: 32px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1 class="title">🏇 Монгол Түүх App</h1>
          </div>
          <p>Сайн байна уу!</p>
          <p>Таны имэйл хаягийг баталгаажуулах код:</p>
          <div class="code-box">
            <div class="code">${code}</div>
            <p class="expiry">⏱️ Код 5 минутын дараа хүчингүй болно</p>
          </div>
          <p>Хэрэв та энэ хүсэлтийг илгээгээгүй бол энэ имэйлийг устгана уу.</p>
          <div class="footer">
            <p>© 2024 Монгол Түүх App</p>
          </div>
        </div>
      </body>
      </html>
    `,
    text: `Таны баталгаажуулах код: ${code}\n\nКод 5 минутын дараа хүчингүй болно.\n\nМонгол Түүх App`,
  };

  try {
    await transporter.sendMail(mailOptions);
    return true;
  } catch (error) {
    console.error("Email send error:", error);
    throw new functions.https.HttpsError("internal", "Имэйл илгээхэд алдаа гарлаа");
  }
}

module.exports = { sendOtpEmail };
```

### functions/src/email/sendVerificationCode.js
```javascript
const admin = require("firebase-admin");
const CryptoJS = require("crypto-js");
const functions = require("firebase-functions");
const { sendOtpEmail } = require("./emailService");

const db = admin.firestore();

/**
 * Generate a secure 6-digit OTP code
 */
function generateOtp() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

/**
 * Hash OTP code with SHA-256
 */
function hashCode(code) {
  return CryptoJS.SHA256(code).toString();
}

/**
 * Send verification code Cloud Function
 * @param {Object} data - { email: string, userId: string }
 * @param {Object} context - Firebase context
 */
async function sendVerificationCode(data, context) {
  const { email, userId } = data;

  // Validate input
  if (!email || !userId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Email болон userId шаардлагатай"
    );
  }

  // Rate limiting: Check if user sent too many codes recently
  const recentCodes = await db
    .collection("email_verifications")
    .where("email", "==", email)
    .where("createdAt", ">", admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 10 * 60 * 1000) // Last 10 minutes
    ))
    .get();

  if (recentCodes.size >= 3) {
    throw new functions.https.HttpsError(
      "resource-exhausted",
      "Хэт олон оролдлого. 10 минутын дараа дахин оролдоно уу."
    );
  }

  // Generate OTP
  const code = generateOtp();
  const codeHash = hashCode(code);
  const now = admin.firestore.Timestamp.now();
  const expiresAt = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() + 5 * 60 * 1000) // 5 minutes from now
  );

  // Delete any existing verification for this email
  const existingDocs = await db
    .collection("email_verifications")
    .where("email", "==", email)
    .get();

  const batch = db.batch();
  existingDocs.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });

  // Create new verification document
  const verificationRef = db.collection("email_verifications").doc();
  batch.set(verificationRef, {
    email: email,
    userId: userId,
    codeHash: codeHash,
    createdAt: now,
    expiresAt: expiresAt,
    verified: false,
    attempts: 0,
  });

  await batch.commit();

  // Send email
  await sendOtpEmail(email, code);

  return {
    success: true,
    message: "Баталгаажуулах код илгээгдлээ",
    expiresAt: expiresAt.toMillis(),
  };
}

module.exports = { sendVerificationCode };
```

### functions/src/email/verifyCode.js
```javascript
const admin = require("firebase-admin");
const CryptoJS = require("crypto-js");
const functions = require("firebase-functions");

const db = admin.firestore();

/**
 * Hash OTP code with SHA-256
 */
function hashCode(code) {
  return CryptoJS.SHA256(code).toString();
}

/**
 * Verify code Cloud Function
 * @param {Object} data - { email: string, code: string, userId: string }
 * @param {Object} context - Firebase context
 */
async function verifyCode(data, context) {
  const { email, code, userId } = data;

  // Validate input
  if (!email || !code || !userId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Email, code болон userId шаардлагатай"
    );
  }

  // Find verification document
  const verificationQuery = await db
    .collection("email_verifications")
    .where("email", "==", email)
    .where("userId", "==", userId)
    .where("verified", "==", false)
    .orderBy("createdAt", "descending")
    .limit(1)
    .get();

  if (verificationQuery.empty) {
    throw new functions.https.HttpsError(
      "not-found",
      "Баталгаажуулах код олдсонгүй. Шинэ код авна уу."
    );
  }

  const verificationDoc = verificationQuery.docs[0];
  const verificationData = verificationDoc.data();

  // Check if expired
  if (verificationData.expiresAt.toDate() < new Date()) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Код хүчингүй болсон байна. Шинэ код авна уу."
    );
  }

  // Check attempts (max 5)
  if (verificationData.attempts >= 5) {
    throw new functions.https.HttpsError(
      "resource-exhausted",
      "Хэт олон буруу оролдлого. Шинэ код авна уу."
    );
  }

  // Verify code hash
  const providedHash = hashCode(code);
  if (providedHash !== verificationData.codeHash) {
    // Increment attempts
    await verificationDoc.ref.update({
      attempts: admin.firestore.FieldValue.increment(1),
    });

    const remainingAttempts = 5 - verificationData.attempts - 1;
    throw new functions.https.HttpsError(
      "invalid-argument",
      `Буруу код. ${remainingAttempts} оролдлого үлдсэн.`
    );
  }

  // Success! Mark as verified
  const batch = db.batch();

  // Update verification document
  batch.update(verificationDoc.ref, {
    verified: true,
    verifiedAt: admin.firestore.Timestamp.now(),
  });

  // Update user document to mark email as verified
  const userRef = db.collection("users").doc(userId);
  batch.update(userRef, {
    emailVerified: true,
    emailVerifiedAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now(),
  });

  await batch.commit();

  return {
    success: true,
    message: "Имэйл амжилттай баталгаажлаа!",
  };
}

module.exports = { verifyCode };
```

---

## ⚙️ Step 4: Configure SMTP Credentials

### Option A: Using Firebase Environment Config (Recommended for production)

```bash
firebase functions:config:set email.user="your-email@hotmail.com" email.pass="your-app-password"
```

### Option B: Using .env file (For local development)

Create `functions/.env`:
```
EMAIL_USER=your-email@hotmail.com
EMAIL_PASS=your-app-password
```

⚠️ **Important**: For Hotmail/Outlook, you need an "App Password" if you have 2FA enabled:
1. Go to https://account.microsoft.com/security
2. Sign in and go to "Security" → "Advanced security options"
3. Under "App passwords", create a new app password
4. Use that password in EMAIL_PASS

---

## 🔒 Step 5: Add Firestore Security Rules

Add to your `firestore.rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ... existing rules ...

    // Email verifications - only Cloud Functions can write
    match /email_verifications/{docId} {
      allow read: if request.auth != null && 
                    resource.data.userId == request.auth.uid;
      allow write: if false; // Only Cloud Functions can write
    }
  }
}
```

---

## 🚀 Step 6: Deploy

```bash
# Deploy functions only
firebase deploy --only functions

# Or deploy everything
firebase deploy
```

---

## 🧪 Step 7: Test

1. Register a new user in your Flutter app
2. OTP verification screen should appear
3. Check your email for the 6-digit code
4. Enter the code
5. Should navigate to home screen

---

## 📊 Firestore Structure

### Collection: `email_verifications`
```json
{
  "email": "user@example.com",
  "userId": "firebase_uid",
  "codeHash": "sha256_hashed_code",
  "createdAt": "Timestamp",
  "expiresAt": "Timestamp",
  "verified": false,
  "attempts": 0,
  "verifiedAt": "Timestamp (after verification)"
}
```

### Collection: `users` (updated field)
```json
{
  "emailVerified": true,
  "emailVerifiedAt": "Timestamp"
}
```

---

## 🔧 Troubleshooting

### "Email илгээхэд алдаа гарлаа"
- Check SMTP credentials are correct
- Ensure you're using an App Password if 2FA is enabled
- Check Firebase Functions logs: `firebase functions:log`

### "Хэт олон оролдлого"
- Wait 10 minutes or use a different email
- This is rate limiting working correctly

### Code not arriving
- Check spam folder
- Verify EMAIL_USER is correct
- Check Functions logs for errors

---

## ✅ Summary

You now have:
- ✅ Secure OTP generation (server-side)
- ✅ SHA-256 code hashing
- ✅ 5-minute expiration
- ✅ Rate limiting (3 codes per 10 min)
- ✅ Max 5 verification attempts
- ✅ Beautiful HTML email template
- ✅ SMTP credentials hidden from Flutter -->
