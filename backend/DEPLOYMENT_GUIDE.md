# Backend Deployment Guide

This guide walks you through deploying the Todo App backend to production.

## Prerequisites

- Node.js 18+ installed locally
- Git installed
- MongoDB Atlas account (free tier)
- Hosting service account (Render/Railway/Fly.io - free tier)
- Firebase project with Admin SDK credentials

## Step 1: Set Up MongoDB Atlas (Free Tier)

### 1.1 Create MongoDB Atlas Account

1. Go to [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
2. Sign up for a free account
3. Create a new project (e.g., "TodoApp")

### 1.2 Create a Free Cluster

1. Click "Build a Database"
2. Choose "M0 Sandbox" (Free tier)
3. Select a cloud provider and region closest to your users
4. Name your cluster (e.g., "todo-app-cluster")
5. Click "Create Cluster"

### 1.3 Configure Database Access

1. Go to "Database Access" in the left sidebar
2. Click "Add New Database User"
3. Choose "Password" authentication
4. Create a username and strong password (save these!)
5. Set user privileges to "Read and write to any database"
6. Click "Add User"

### 1.4 Configure Network Access

1. Go to "Network Access" in the left sidebar
2. Click "Add IP Address"
3. Click "Allow Access from Anywhere" (0.0.0.0/0)
   - Note: For production, restrict to your hosting service's IP ranges
4. Click "Confirm"

### 1.5 Get Connection String

1. Go to "Database" in the left sidebar
2. Click "Connect" on your cluster
3. Choose "Connect your application"
4. Copy the connection string (looks like: `mongodb+srv://username:<password>@cluster.mongodb.net/`)
5. Replace `<password>` with your database user password
6. Add database name at the end: `mongodb+srv://username:password@cluster.mongodb.net/todo-app`

## Step 2: Prepare Firebase Admin SDK

### 2.1 Get Firebase Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click the gear icon → "Project settings"
4. Go to "Service accounts" tab
5. Click "Generate new private key"
6. Download the JSON file (keep it secure!)

### 2.2 Extract Required Values

From the downloaded JSON file, you'll need:
- `project_id`
- `private_key` (the entire key including BEGIN/END markers)
- `client_email`

## Step 3: Deploy to Render (Recommended)

### 3.1 Create Render Account

1. Go to [Render](https://render.com/)
2. Sign up with GitHub (recommended for easy deployment)

### 3.2 Create New Web Service

1. Click "New +" → "Web Service"
2. Connect your GitHub repository
3. Configure the service:
   - **Name**: `todo-app-backend`
   - **Region**: Choose closest to your users
   - **Branch**: `main` (or your default branch)
   - **Root Directory**: `backend`
   - **Runtime**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Instance Type**: `Free`

### 3.3 Configure Environment Variables

In the Render dashboard, add these environment variables:

```
NODE_ENV=production
PORT=3000
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/todo-app
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYour private key here\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@your-project-id.iam.gserviceaccount.com
ALLOWED_ORIGINS=capacitor://localhost,ionic://localhost,https://yourdomain.com
```

**Important Notes:**
- For `FIREBASE_PRIVATE_KEY`, copy the entire key from the JSON file including `\n` characters
- Wrap the private key in double quotes
- Add your actual domain to `ALLOWED_ORIGINS` once you have one

### 3.4 Deploy

1. Click "Create Web Service"
2. Render will automatically deploy your app
3. Wait for the build to complete (5-10 minutes)
4. Your API will be available at: `https://todo-app-backend.onrender.com`

### 3.5 Test Deployment

Test the health endpoint:
```bash
curl https://todo-app-backend.onrender.com/health
```

Expected response:
```json
{"status":"ok","timestamp":"2024-01-01T00:00:00.000Z"}
```

## Alternative: Deploy to Railway

### Railway Setup

1. Go to [Railway](https://railway.app/)
2. Sign up with GitHub
3. Click "New Project" → "Deploy from GitHub repo"
4. Select your repository
5. Railway will auto-detect Node.js

### Railway Configuration

Add environment variables in Railway dashboard (same as Render above)

Set root directory:
```bash
railway up --rootDir backend
```

Your API will be at: `https://your-app.railway.app`

## Alternative: Deploy to Fly.io

### Fly.io Setup

1. Install Fly CLI: `curl -L https://fly.io/install.sh | sh`
2. Sign up: `fly auth signup`
3. Navigate to backend directory: `cd backend`

### Create fly.toml

Create `backend/fly.toml`:
```toml
app = "todo-app-backend"

[build]
  builder = "heroku/buildpacks:20"

[env]
  PORT = "8080"
  NODE_ENV = "production"

[[services]]
  internal_port = 8080
  protocol = "tcp"

  [[services.ports]]
    handlers = ["http"]
    port = 80

  [[services.ports]]
    handlers = ["tls", "http"]
    port = 443
```

### Deploy to Fly.io

```bash
fly launch
fly secrets set MONGODB_URI="your-mongodb-uri"
fly secrets set FIREBASE_PROJECT_ID="your-project-id"
fly secrets set FIREBASE_PRIVATE_KEY="your-private-key"
fly secrets set FIREBASE_CLIENT_EMAIL="your-client-email"
fly secrets set ALLOWED_ORIGINS="capacitor://localhost,ionic://localhost"
fly deploy
```

Your API will be at: `https://todo-app-backend.fly.dev`

## Step 4: Verify Deployment

### 4.1 Test Health Endpoint

```bash
curl https://your-deployed-url.com/health
```

### 4.2 Test Authentication Endpoint

```bash
curl -X POST https://your-deployed-url.com/api/auth/verify \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_FIREBASE_TOKEN"
```

### 4.3 Monitor Logs

**Render**: View logs in the dashboard under "Logs" tab

**Railway**: `railway logs`

**Fly.io**: `fly logs`

## Step 5: Production Checklist

- [ ] MongoDB Atlas cluster created and configured
- [ ] Database user created with strong password
- [ ] Network access configured (0.0.0.0/0 or specific IPs)
- [ ] Firebase Admin SDK credentials obtained
- [ ] Backend deployed to hosting service
- [ ] Environment variables configured correctly
- [ ] Health endpoint returns 200 OK
- [ ] API endpoints tested with valid Firebase token
- [ ] CORS configured for mobile app origins
- [ ] Logs monitored for errors

## Troubleshooting

### MongoDB Connection Issues

**Error**: `MongoServerError: bad auth`
- **Solution**: Verify username and password in connection string
- Ensure database user has correct permissions

**Error**: `MongooseServerSelectionError: connect ETIMEDOUT`
- **Solution**: Check Network Access whitelist in MongoDB Atlas
- Ensure 0.0.0.0/0 is added or your hosting service's IPs

### Firebase Authentication Issues

**Error**: `auth/invalid-credential`
- **Solution**: Verify Firebase credentials are correct
- Check that private key includes `\n` characters
- Ensure private key is wrapped in double quotes

### CORS Issues

**Error**: `CORS policy violation`
- **Solution**: Add your app's origin to `ALLOWED_ORIGINS`
- For mobile apps, include: `capacitor://localhost,ionic://localhost`

### Deployment Fails

**Render/Railway**: Check build logs for npm install errors
- Ensure `package.json` is in the backend directory
- Verify Node.js version compatibility

**Fly.io**: Check `fly logs` for startup errors
- Ensure PORT environment variable matches fly.toml

## Monitoring and Maintenance

### Free Tier Limitations

**Render Free Tier**:
- Spins down after 15 minutes of inactivity
- First request after spin-down takes 30-60 seconds
- 750 hours/month free

**Railway Free Tier**:
- $5 credit per month
- No automatic spin-down

**Fly.io Free Tier**:
- 3 shared-cpu-1x VMs
- 160GB bandwidth/month

### Keeping Service Alive (Render)

To prevent spin-down, ping your health endpoint every 10 minutes:
- Use a service like [UptimeRobot](https://uptimerobot.com/) (free)
- Or use a cron job: `*/10 * * * * curl https://your-app.onrender.com/health`

## Security Best Practices

1. **Never commit secrets**: Keep `.env` files out of version control
2. **Use strong passwords**: For MongoDB users
3. **Restrict CORS**: Only allow necessary origins
4. **Monitor logs**: Check for suspicious activity
5. **Update dependencies**: Regularly run `npm audit fix`
6. **Use HTTPS only**: All hosting services provide free SSL

## Next Steps

After successful deployment:
1. Save your production API URL
2. Update Flutter app with production URL (see Task 16.2)
3. Test authentication and sync from mobile app
4. Monitor logs for any errors
5. Set up crash reporting (see Task 16.4)

## Support

If you encounter issues:
- Check hosting service documentation
- Review MongoDB Atlas documentation
- Consult Firebase Admin SDK documentation
- Check application logs for specific error messages
