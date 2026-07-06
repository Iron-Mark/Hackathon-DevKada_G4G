# Supabase Phone OTP Integration (Kudlit)

This guide documents the Supabase setup needed for the app's phone OTP flow.
The Flutter flow is wired in code, but it still depends on Supabase phone auth
and SMS delivery being configured in the target environment.

## 1. Enable Phone Provider

In Supabase Dashboard:

1. Go to **Authentication** -> **Providers**.
2. Open **Phone**.
3. Toggle Phone auth **Enabled**.

## 2. Configure SMS Delivery

Choose one of these:

- **Production SMS provider** (recommended for real users)
- **Test/dev setup** (for local OTP flow testing)

If SMS delivery is not configured, OTP requests will fail even if the app code
is correct.

## 3. Configure Auth URLs

In **Authentication** -> **URL Configuration**:

- Set your app/site URL correctly.
- Add redirect/deep-link URLs used by Kudlit.

## 4. Review OTP Security Settings

In **Authentication settings** (or Auth configuration), confirm:

- OTP expiration window
- Rate limits / resend constraints
- Any anti-abuse settings appropriate for testing vs production

## 5. App Integration Points (Flutter)

When integrating in-app, use:

1. Request OTP

```dart
await supabase.auth.signInWithOtp(
  phone: phoneNumber,
);
```

2. Verify OTP

```dart
await supabase.auth.verifyOTP(
  phone: phoneNumber,
  token: otpCode,
  type: OtpType.sms,
);
```

## 6. Quick Troubleshooting

- **No OTP sent**: Phone provider disabled or SMS provider not configured.
- **OTP verification fails**: Wrong code, expired code, or phone mismatch.
- **Works in dashboard but not app**: Check app env values and Supabase URL/key.
- **Redirect/deep-link issues**: Recheck URL configuration.

## 7. Pre-Integration Checklist

- [ ] Phone provider enabled
- [ ] SMS delivery configured
- [ ] URL/deep-link config validated
- [ ] OTP expiry and rate limits reviewed
- [ ] Test number flow passes end-to-end
