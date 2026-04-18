# Firebase Email Authentication Setup Guide

## 📧 Email Verification & Password Reset System

Таны Flutter app-д одоо дараах функцууд нэмэгдсэн:
1. ✅ Email verification after signup
2. ✅ Password reset via email
3. ✅ Auto-check email verification status
4. ✅ Resend verification email

---

## 🔧 Firebase Console Setup

### 1. Enable Email/Password Authentication
1. Firebase Console руу орно: https://console.firebase.google.com
2. Төслөө сонгоно
3. **Authentication** > **Sign-in method** руу орно
4. **Email/Password** -г идэвхжүүлнэ (Enable)
5. **Save** дарна

### 2. Configure Email Templates

Firebase automatically sends emails when you call:
- `sendEmailVerification()` → Email Verification
- `sendPasswordResetEmail()` → Password Reset

#### Customize Email Templates:
1. Firebase Console > **Authentication** > **Templates** tab
2. **Email address verification** template засах:
   ```
   Subject: Verify your email for Mongolian History App
   
   Hi %DISPLAY_NAME%,
   
   Please verify your email by clicking the link below:
   %LINK%
   
   If you didn't sign up for Mongolian History App, ignore this email.
   ```

3. **Password reset** template засах:
   ```
   Subject: Reset your password for Mongolian History App
   
   Hi,
   
   Click the link below to reset your password:
   %LINK%
   
   If you didn't request this, ignore this email.
   
   This link expires in 1 hour.
   ```

### 3. Configure Authorized Domains

1. Firebase Console > **Authentication** > **Settings**
2. **Authorized domains** хэсэгт domains нэмнэ:
   - `localhost` (development үед)
   - `your-app-domain.com` (production үед)

### 4. Email Sender Configuration

Firebase автоматаар `noreply@your-project-id.firebaseapp.com` хаягаас илгээнэ.

**Custom email domain ашиглах:**
1. Firebase Console > **Authentication** > **Templates**
2. **Customize email address** дээр дарна
3. Domain verification хийнэ (DNS records нэмэх шаардлагатай)

---

## 📱 App Integration - Already Done!

### Files Created:
1. ✅ `lib/screens/email_verification_screen.dart` - Email баталгаажуулалт
2. ✅ `lib/screens/forgot_password_screen.dart` - Password reset
3. ✅ `lib/services/auth_service.dart` - Email функцууд нэмэгдсэн

### Files Modified:
1. ✅ `lib/screens/auth_gate.dart` - Email verified шалгах
2. ✅ `lib/screens/login_screen.dart` - Forgot password линк
3. ✅ `lib/screens/register_screen.dart` - Auto-send verification email
4. ✅ `lib/providers/auth_provider.dart` - `isEmailVerified` getter

---

## 🎯 User Flow

### Signup Flow:
```
1. User бүртгүүлнэ (RegisterScreen)
   ↓
2. Firebase account үүснэ
   ↓
3. Verification email автоматаар илгээгдэнэ
   ↓
4. EmailVerificationScreen гарч ирнэ
   ↓
5. User имэйлээ шалгаад link дээр дарна
   ↓
6. App 3 секунд тутамд auto-check хийнэ
   ↓
7. Verified болоход HomeScreen руу орно
```

### Password Reset Flow:
```
1. LoginScreen дээр "Нууц үг мартсан?" дарна
   ↓
2. ForgotPasswordScreen руу орно
   ↓
3. Имэйл оруулна
   ↓
4. Password reset email илгээгдэнэ
   ↓
5. User имэйл дээрх link дээр дарна
   ↓
6. Firebase hosted password reset page гарна
   ↓
7. Шинэ password оруулна
   ↓
8. LoginScreen руу буцаж шинэ password-оор нэвтрэнэ
```

---

## 🔐 Security Features

### Email Verification:
- ✅ Баталгаажаагүй users app-д орж чадахгүй
- ✅ Auto-check every 3 seconds
- ✅ Resend email with 60 second cooldown
- ✅ Email verified хүртэл HomeScreen blocked

### Password Reset:
- ✅ Reset link 1 цагийн дараа expire хийгдэнэ
- ✅ Link нэг удаа л ашиглаж болно
- ✅ Email validation before sending
- ✅ Rate limiting (too-many-requests)

---

## 🧪 Testing

### Test Email Verification:
1. Шинэ хэрэглэгч бүртгүүлнэ
2. Console log-оос verification link харна:
   ```bash
   flutter run
   ```
3. Эсвэл Firebase Console > Authentication > Users > click user > Send verification email

### Test Password Reset:
1. LoginScreen дээр "Нууц үг мартсан?" дарна
2. Бүртгэлтэй имэйл оруулна
3. Console log эсвэл имэйл дээрээс reset link авна

### Enable Email Link Preview in Development:
Firebase Console > Authentication > Templates > click any template > scroll down > **Preview** button

---

## 📧 Email Service Providers

Firebase supports sending via:
1. **Firebase default SMTP** (free, limited)
2. **SendGrid** integration
3. **Mailgun** integration
4. **Custom SMTP** (Cloud Functions ашиглах)

For production with high volume:
- Configure SendGrid/Mailgun for better deliverability
- Use custom domain for professional emails

---

## 🐛 Troubleshooting

### Email ирэхгүй байна:
1. Spam folder шалгана
2. Firebase Console > Authentication > Templates > Email verified эсэхийг шалгана
3. Authorized domains дээр domain нэмэгдсэн эсэхийг шалгана

### "Email not verified" error:
```dart
await FirebaseAuth.instance.currentUser?.reload();
```

### Rate limit error:
- 60 секунд хүлээнэ
- Firebase quota шалгана

---

## 📚 Additional Resources

- [Firebase Auth Email Verification](https://firebase.google.com/docs/auth/flutter/manage-users#send_a_user_a_verification_email)
- [Firebase Password Reset](https://firebase.google.com/docs/auth/flutter/manage-users#send_a_password_reset_email)
- [Email Templates](https://firebase.google.com/docs/auth/custom-email-handler)

---

## ✅ Summary

Таны app-д одоо бүрэн email verification болон password reset систем байна:

**Features:**
- ✅ Auto-send verification email on signup
- ✅ Beautiful verification waiting screen
- ✅ Auto-detect when email is verified
- ✅ Resend email functionality
- ✅ Password reset via email
- ✅ Secure Firebase-hosted reset page
- ✅ Customizable email templates
- ✅ Production-ready security

**Next Steps:**
1. Firebase Console дээр email templates засна
2. Custom domain тохируулна (optional)
3. Production email service provider сонгоно (SendGrid/Mailgun)

Бүх зүйл бэлэн! 🎉
