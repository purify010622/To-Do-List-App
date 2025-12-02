# MongoDB Atlas Setup Guide

This guide provides detailed instructions for setting up MongoDB Atlas for the Todo App backend.

## Overview

MongoDB Atlas is a fully-managed cloud database service. The free tier (M0 Sandbox) provides:
- 512 MB storage
- Shared RAM
- Shared vCPU
- Perfect for development and small production apps

## Step-by-Step Setup

### 1. Create MongoDB Atlas Account

1. Navigate to [https://www.mongodb.com/cloud/atlas/register](https://www.mongodb.com/cloud/atlas/register)
2. Sign up using:
   - Email and password, OR
   - Google account, OR
   - GitHub account
3. Complete email verification if required

### 2. Create Organization and Project

1. After login, you'll be prompted to create an organization
   - **Organization Name**: Your company/personal name
   - Click "Next"

2. Create a project
   - **Project Name**: `TodoApp` (or your preferred name)
   - Click "Next"
   - Skip adding members (or add team members if needed)
   - Click "Create Project"

### 3. Build Your First Cluster

1. Click "Build a Database" button
2. Choose deployment option:
   - Select **"M0 Sandbox"** (FREE)
   - This is the free tier option

3. Configure cluster:
   - **Cloud Provider**: Choose AWS, Google Cloud, or Azure
   - **Region**: Select region closest to your users or hosting service
     - For Render (Oregon): Choose `us-west-2` (AWS) or `us-west1` (GCP)
     - For Railway: Choose based on your deployment region
     - For Fly.io: Choose based on your primary region
   
4. Cluster configuration:
   - **Cluster Name**: `todo-app-cluster` (or your preferred name)
   - Leave other settings as default
   
5. Click "Create Cluster"
   - Cluster creation takes 3-5 minutes

### 4. Configure Database Access (Create Database User)

1. While cluster is being created, click "Database Access" in left sidebar
2. Click "Add New Database User"
3. Configure user:
   - **Authentication Method**: Password
   - **Username**: `todoapp_user` (or your preferred username)
   - **Password**: Click "Autogenerate Secure Password" or create your own
     - **IMPORTANT**: Copy and save this password securely!
   - **Database User Privileges**: 
     - Select "Built-in Role"
     - Choose "Read and write to any database"
   - **Temporary User**: Leave unchecked
4. Click "Add User"

**Security Note**: Store credentials securely. Never commit them to version control.

### 5. Configure Network Access (IP Whitelist)

1. Click "Network Access" in left sidebar
2. Click "Add IP Address"
3. Configure access:

   **Option A: Allow from Anywhere (Easiest for getting started)**
   - Click "Allow Access from Anywhere"
   - This adds `0.0.0.0/0` to the whitelist
   - Click "Confirm"
   - ⚠️ **Note**: This is less secure but works with any hosting service

   **Option B: Specific IP Addresses (More Secure)**
   - Add your hosting service's IP ranges:
     
     **For Render**:
     - Render uses dynamic IPs, so use Option A or contact Render support for IP ranges
     
     **For Railway**:
     - Railway provides static IPs on paid plans
     - Free tier: Use Option A
     
     **For Fly.io**:
     - Get your app's IP: `fly ips list`
     - Add each IP to the whitelist

4. Click "Confirm"

### 6. Get Connection String

1. Wait for cluster to finish creating (status shows "Active")
2. Click "Database" in left sidebar
3. Find your cluster and click "Connect"
4. Choose connection method: "Connect your application"
5. Configure connection:
   - **Driver**: Node.js
   - **Version**: 5.5 or later
6. Copy the connection string:
   ```
   mongodb+srv://<username>:<password>@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
   ```

### 7. Format Connection String for Your App

Replace placeholders in the connection string:

**Original**:
```
mongodb+srv://<username>:<password>@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
```

**Updated** (example):
```
mongodb+srv://todoapp_user:MySecurePass123@todo-app-cluster.abc123.mongodb.net/todo-app?retryWrites=true&w=majority
```

**Important replacements**:
- `<username>`: Your database username (e.g., `todoapp_user`)
- `<password>`: Your database password (URL-encode special characters!)
- Add database name before the `?`: `/todo-app`

**URL Encoding Special Characters**:
If your password contains special characters, encode them:
- `@` → `%40`
- `:` → `%3A`
- `/` → `%2F`
- `?` → `%3F`
- `#` → `%23`
- `[` → `%5B`
- `]` → `%5D`
- `%` → `%25`

Example: Password `Pass@123!` becomes `Pass%40123!`

### 8. Test Connection Locally

Before deploying, test the connection:

1. Create a test file `backend/test-connection.js`:
```javascript
require('dotenv').config();
const mongoose = require('mongoose');

const MONGODB_URI = 'your-connection-string-here';

mongoose.connect(MONGODB_URI)
  .then(() => {
    console.log('✅ Successfully connected to MongoDB Atlas!');
    console.log('Database:', mongoose.connection.name);
    mongoose.connection.close();
  })
  .catch((err) => {
    console.error('❌ Connection failed:', err.message);
  });
```

2. Run the test:
```bash
cd backend
node test-connection.js
```

3. Expected output:
```
✅ Successfully connected to MongoDB Atlas!
Database: todo-app
```

### 9. Configure for Production

Add the connection string to your hosting service's environment variables:

**Render**:
1. Go to your web service dashboard
2. Click "Environment" tab
3. Add variable:
   - Key: `MONGODB_URI`
   - Value: Your full connection string
4. Click "Save Changes"

**Railway**:
1. Go to your project
2. Click "Variables" tab
3. Add variable:
   - Key: `MONGODB_URI`
   - Value: Your full connection string

**Fly.io**:
```bash
fly secrets set MONGODB_URI="mongodb+srv://YOUR_USERNAME:YOUR_PASSWORD@your-cluster.mongodb.net/your-database?retryWrites=true&w=majority"
```

### 10. Verify Database Collections

After deploying and running your app:

1. Go to MongoDB Atlas dashboard
2. Click "Database" → "Browse Collections"
3. Select your database (`todo-app`)
4. You should see collections created by your app:
   - `tasks` - Stores all task data
   - `users` (if implemented)

## Database Schema

Your app will automatically create these collections:

### tasks Collection

```javascript
{
  _id: ObjectId("..."),
  userId: "firebase-uid-here",
  taskId: "uuid-here",
  title: "Task title",
  description: "Task description",
  priority: 3,
  dueDate: ISODate("2024-01-01T00:00:00.000Z"),
  completed: false,
  createdAt: ISODate("2024-01-01T00:00:00.000Z"),
  updatedAt: ISODate("2024-01-01T00:00:00.000Z")
}
```

### Indexes

The app creates these indexes for performance:
- `userId` - For filtering tasks by user
- `priority` - For sorting by priority
- `dueDate` - For sorting by due date

## Monitoring and Maintenance

### View Database Metrics

1. Go to MongoDB Atlas dashboard
2. Click "Metrics" tab
3. Monitor:
   - Connections
   - Operations per second
   - Network traffic
   - Storage usage

### Free Tier Limits

- **Storage**: 512 MB
- **Connections**: 500 concurrent
- **Bandwidth**: Unlimited (but throttled)

### Backup

Free tier includes:
- Automatic daily snapshots (retained for 2 days)
- Point-in-time recovery (not available on free tier)

### Upgrade Path

When you need more resources:
1. Click "Upgrade" on your cluster
2. Choose M10 or higher tier
3. Pricing starts at ~$0.08/hour (~$57/month)

## Troubleshooting

### Connection Timeout

**Error**: `MongooseServerSelectionError: connect ETIMEDOUT`

**Solutions**:
1. Check Network Access whitelist
2. Verify IP address is allowed (0.0.0.0/0 or specific IP)
3. Check if cluster is active (not paused)
4. Verify connection string format

### Authentication Failed

**Error**: `MongoServerError: bad auth`

**Solutions**:
1. Verify username and password are correct
2. Check for special characters in password (URL encode them)
3. Ensure database user has correct permissions
4. Try resetting the user's password

### Database Not Found

**Error**: `Database 'todo-app' not found`

**Solution**:
- This is normal! MongoDB creates databases on first write
- The database will be created when your app first saves data
- Ensure database name is in connection string: `/todo-app?`

### IP Not Whitelisted

**Error**: `MongooseServerSelectionError: connection refused`

**Solutions**:
1. Add 0.0.0.0/0 to Network Access
2. Or add your hosting service's specific IPs
3. Wait 1-2 minutes after adding IPs for changes to propagate

### Cluster Paused

**Error**: `Cluster is paused`

**Solution**:
- Free tier clusters pause after 60 days of inactivity
- Click "Resume" in the Atlas dashboard
- Cluster resumes in 1-2 minutes

## Security Best Practices

1. **Strong Passwords**: Use complex passwords (20+ characters)
2. **Rotate Credentials**: Change passwords periodically
3. **Limit IP Access**: Use specific IPs when possible
4. **Monitor Access**: Check "Access Manager" for unusual activity
5. **Enable Alerts**: Set up email alerts for security events
6. **Audit Logs**: Review database access logs (available on paid tiers)

## Cost Management

### Staying on Free Tier

- Monitor storage usage (512 MB limit)
- Implement data retention policies
- Delete old completed tasks periodically
- Optimize document sizes

### Monitoring Usage

1. Go to "Billing" in organization settings
2. View current usage
3. Set up billing alerts

## Additional Resources

- [MongoDB Atlas Documentation](https://docs.atlas.mongodb.com/)
- [Connection String Format](https://docs.mongodb.com/manual/reference/connection-string/)
- [Security Checklist](https://docs.atlas.mongodb.com/security-checklist/)
- [Performance Best Practices](https://docs.atlas.mongodb.com/performance-advisor/)

## Support

If you need help:
- MongoDB Atlas Support: [https://support.mongodb.com/](https://support.mongodb.com/)
- Community Forums: [https://www.mongodb.com/community/forums/](https://www.mongodb.com/community/forums/)
- Documentation: [https://docs.atlas.mongodb.com/](https://docs.atlas.mongodb.com/)
