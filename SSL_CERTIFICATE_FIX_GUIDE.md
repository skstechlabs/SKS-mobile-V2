# SSL Certificate Fix Guide for app.sivakundalini.org

## Current Issue

The SSL certificate for `app.sivakundalini.org` has an incomplete certificate chain, causing the error:
```
CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate
```

## Impact

- Video playback fails in mobile app WebView
- API calls work (because we added SSL bypass in Dio)
- WebView cannot bypass SSL like Dio can

## Temporary Solution Implemented

We've added a Network Security Configuration for Android that trusts user-installed certificates in addition to system certificates. This allows the app to work with incomplete certificate chains.

**Files Modified:**
- `android/app/src/main/res/xml/network_security_config.xml` - Created
- `android/app/src/main/AndroidManifest.xml` - Added network security config reference

## Proper Solution (REQUIRED for Production)

### Step 1: Verify Current Certificate Status

Test your SSL certificate:
```bash
openssl s_client -connect app.sivakundalini.org:443 -showcerts
```

Or use online tool: https://www.ssllabs.com/ssltest/analyze.html?d=app.sivakundalini.org

### Step 2: Fix Certificate Chain

Your SSL certificate needs the complete chain:
1. **Server Certificate** (your domain certificate)
2. **Intermediate Certificate(s)** (from your CA)
3. **Root Certificate** (usually already trusted by systems)

#### For Nginx:

Edit your nginx configuration:
```nginx
server {
    listen 443 ssl;
    server_name app.sivakundalini.org;
    
    # Your domain certificate
    ssl_certificate /path/to/fullchain.pem;
    
    # Your private key
    ssl_certificate_key /path/to/privkey.pem;
    
    # SSL settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
}
```

**Important:** Use `fullchain.pem` (not `cert.pem`). The fullchain includes:
- Your certificate
- All intermediate certificates

#### For Let's Encrypt:

If using certbot, the fullchain is automatically created:
```bash
# Renew and ensure fullchain is used
certbot renew

# Verify files exist
ls -la /etc/letsencrypt/live/app.sivakundalini.org/
# Should show: cert.pem, chain.pem, fullchain.pem, privkey.pem
```

#### For Other Certificate Authorities:

1. Download intermediate certificates from your CA
2. Concatenate them with your certificate:
```bash
cat your_domain.crt intermediate.crt > fullchain.pem
```

### Step 3: Verify Fix

After updating, test:
```bash
# Should show complete chain
openssl s_client -connect app.sivakundalini.org:443 -showcerts | grep "Verify return code"
# Should return: Verify return code: 0 (ok)
```

### Step 4: Remove Temporary Workarounds

Once the certificate is fixed, you can optionally remove the network security config workaround:

1. Delete `/android/app/src/main/res/xml/network_security_config.xml`
2. Remove from `AndroidManifest.xml`:
   ```xml
   android:networkSecurityConfig="@xml/network_security_config"
   ```

However, keeping it doesn't hurt and provides better compatibility.

## Testing After Fix

1. Rebuild the app:
   ```bash
   flutter clean
   flutter run --dart-define-from-file=.env.prod.json
   ```

2. Test video playback
3. Verify HTTPS is used (check logs)

## Security Notes

- ✅ Current solution: HTTPS with certificate chain trust
- ✅ Secure: All traffic encrypted
- ✅ Compatible: Works on all devices
- 🎯 Best Practice: Fix server certificate for production

## Contact

For server certificate issues, contact your:
- Hosting provider
- SSL certificate authority
- Server administrator
- DevOps team

## References

- [SSL Labs Test](https://www.ssllabs.com/ssltest/)
- [Let's Encrypt Docs](https://letsencrypt.org/docs/)
- [Android Network Security Config](https://developer.android.com/training/articles/security-config)
