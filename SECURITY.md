# Security Guidelines

## ⚠️ CRITICAL: Never Commit These Files

The following files contain sensitive credentials and should NEVER be committed to version control:

### Backend
- `backend/.env` - Contains MongoDB credentials and Firebase keys
- `backend/*firebase-adminsdk*.json` - Firebase service account private keys
- Any file with actual passwords or API keys

### Flutter App
- `todo_app_offline_sync/android/key.properties` - Android signing credentials
- `todo_app_offline_sync/android/app/upload-keystore.jks` - Android keystore file
- Any `.jks` or `.keystore` files

## ✅ Safe to Commit

These example/template files are safe:
- `backend/.env.example` - Template with placeholder values
- `todo_app_offline_sync/android/key.properties.example` - Template for signing config
- Documentation files (*.md)

## 🔒 What to Do Before Pushing to GitHub

1. **Check .gitignore files are in place**
   - Root `.gitignore`
   - `backend/.gitignore`
   - `todo_app_offline_sync/.gitignore`

2. **Verify no credentials in code**
   ```bash
   # Search for potential secrets
   git grep -i "password"
   git grep -i "private_key"
   git grep -i "mongodb+srv://"
   ```

3. **Use environment variables**
   - All secrets should be in `.env` files (which are gitignored)
   - Use `process.env.VARIABLE_NAME` in code
   - Never hardcode credentials

4. **Review files before committing**
   ```bash
   git status
   git diff
   ```

## 🚨 If You Accidentally Committed Secrets

1. **Immediately rotate all credentials:**
   - Change MongoDB password
   - Regenerate Firebase service account key
   - Generate new Android signing key

2. **Remove from Git history:**
   ```bash
   # Use git-filter-repo or BFG Repo-Cleaner
   # Or create a new repository with clean history
   ```

3. **Update .gitignore and recommit**

## 📝 Credential Management

### For Development
- Copy `.env.example` to `.env`
- Fill in your actual credentials in `.env`
- Never share `.env` file

### For Production
- Use hosting service's environment variable management
- Render: Dashboard > Environment
- Railway: Dashboard > Variables
- Fly.io: `fly secrets set KEY=value`

## 🔐 Best Practices

1. **Use strong passwords** - Minimum 16 characters, mixed case, numbers, symbols
2. **Rotate credentials regularly** - Every 90 days for production
3. **Limit access** - Only give credentials to team members who need them
4. **Use separate credentials** - Different for dev/staging/production
5. **Enable 2FA** - On MongoDB Atlas, Firebase Console, GitHub

## 📞 Security Contact

If you discover a security vulnerability, please email: [your-email@example.com]

Do NOT create a public GitHub issue for security vulnerabilities.
