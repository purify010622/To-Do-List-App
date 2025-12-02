# Backend Deployment Checklist

Use this checklist to ensure successful deployment of the Todo App backend.

## Pre-Deployment

### MongoDB Atlas Setup
- [ ] MongoDB Atlas account created
- [ ] Free tier cluster (M0 Sandbox) created
- [ ] Database user created with strong password
- [ ] Password saved securely (password manager recommended)
- [ ] Network access configured (0.0.0.0/0 or specific IPs)
- [ ] Connection string obtained and formatted correctly
- [ ] Connection string tested locally
- [ ] Special characters in password URL-encoded

### Firebase Setup
- [ ] Firebase project exists
- [ ] Firebase Admin SDK service account key downloaded
- [ ] `project_id` extracted from JSON
- [ ] `private_key` extracted from JSON (with \n characters)
- [ ] `client_email` extracted from JSON
- [ ] Credentials stored securely

### Code Preparation
- [ ] All code committed to Git repository
- [ ] `.env` file NOT committed (in .gitignore)
- [ ] `package.json` has correct start script
- [ ] Dependencies are up to date (`npm audit fix`)
- [ ] Backend code tested locally
- [ ] Health endpoint works: `http://localhost:3000/health`

## Hosting Service Setup

### Choose Your Platform
- [ ] Render (recommended for beginners)
- [ ] Railway (good balance of features)
- [ ] Fly.io (more control, CLI-based)

### Render Deployment
- [ ] Render account created
- [ ] GitHub repository connected
- [ ] Web service created
- [ ] Root directory set to `backend`
- [ ] Build command: `npm install`
- [ ] Start command: `npm start`
- [ ] Instance type: Free

### Railway Deployment
- [ ] Railway account created
- [ ] GitHub repository connected
- [ ] Project created
- [ ] Root directory configured
- [ ] Environment variables added

### Fly.io Deployment
- [ ] Fly CLI installed
- [ ] Fly account created (`fly auth signup`)
- [ ] `fly.toml` configured
- [ ] App launched (`fly launch`)
- [ ] Secrets configured (`fly secrets set`)

## Environment Variables Configuration

### Required Variables
- [ ] `NODE_ENV` = `production`
- [ ] `PORT` = `3000` (or `8080` for Fly.io)
- [ ] `MONGODB_URI` = Your MongoDB Atlas connection string
- [ ] `FIREBASE_PROJECT_ID` = Your Firebase project ID
- [ ] `FIREBASE_PRIVATE_KEY` = Your Firebase private key (with quotes)
- [ ] `FIREBASE_CLIENT_EMAIL` = Your Firebase client email
- [ ] `ALLOWED_ORIGINS` = `capacitor://localhost,ionic://localhost`

### Variable Verification
- [ ] All variables added to hosting service
- [ ] Private key includes `\n` characters
- [ ] Private key wrapped in double quotes
- [ ] No trailing spaces in values
- [ ] MongoDB URI includes database name (`/todo-app`)
- [ ] MongoDB password special characters URL-encoded

## Deployment

### Initial Deployment
- [ ] Deployment triggered (automatic or manual)
- [ ] Build logs checked for errors
- [ ] Build completed successfully
- [ ] Service started without errors
- [ ] Deployment URL obtained

### Post-Deployment Verification
- [ ] Health endpoint accessible: `https://your-app.com/health`
- [ ] Health endpoint returns 200 OK
- [ ] Response includes `{"status":"ok","timestamp":"..."}`
- [ ] No errors in application logs

## API Testing

### Health Check
```bash
curl https://your-deployed-url.com/health
```
- [ ] Returns 200 status code
- [ ] Returns JSON with status "ok"

### Authentication Endpoint
```bash
curl -X POST https://your-deployed-url.com/api/auth/verify \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TEST_TOKEN"
```
- [ ] Endpoint accessible
- [ ] Returns appropriate response (401 for invalid token is OK)

### CORS Configuration
- [ ] Mobile app origins included in ALLOWED_ORIGINS
- [ ] CORS headers present in responses
- [ ] No CORS errors when testing from mobile app

## Database Verification

### MongoDB Atlas
- [ ] Connection successful (check logs)
- [ ] Database created (`todo-app`)
- [ ] Collections appear after first API call
- [ ] No authentication errors in logs
- [ ] No connection timeout errors

### Database Operations
- [ ] Can create tasks via API
- [ ] Can read tasks via API
- [ ] Can update tasks via API
- [ ] Can delete tasks via API
- [ ] Data persists across requests

## Monitoring Setup

### Logging
- [ ] Application logs accessible
- [ ] No critical errors in logs
- [ ] Startup logs show successful connections
- [ ] Request logs working

### Uptime Monitoring (Optional)
- [ ] UptimeRobot configured (for Render free tier)
- [ ] Health check pings every 10 minutes
- [ ] Email alerts configured for downtime

### Performance
- [ ] API response times acceptable (<2s)
- [ ] No memory leaks observed
- [ ] CPU usage within limits

## Security Verification

### Credentials
- [ ] No secrets in Git repository
- [ ] `.env` file in `.gitignore`
- [ ] Environment variables secure in hosting service
- [ ] Firebase private key not exposed

### API Security
- [ ] HTTPS enabled (automatic on all platforms)
- [ ] CORS properly configured
- [ ] Rate limiting active
- [ ] Authentication required for protected endpoints
- [ ] Input validation working

### Network Security
- [ ] MongoDB network access configured
- [ ] No unnecessary ports exposed
- [ ] Security headers present (helmet middleware)

## Documentation

### Deployment Info
- [ ] Production URL documented
- [ ] Environment variables documented (without values)
- [ ] Deployment date recorded
- [ ] Hosting service details noted

### Access Information
- [ ] Hosting service login credentials saved
- [ ] MongoDB Atlas login credentials saved
- [ ] Firebase console access documented
- [ ] Team members granted access (if applicable)

## Flutter App Integration

### Configuration
- [ ] Production API URL saved
- [ ] Ready to update Flutter app (Task 16.2)
- [ ] CORS origins include mobile app schemes

## Troubleshooting Checklist

If deployment fails, check:

### Build Failures
- [ ] `package.json` exists in backend directory
- [ ] All dependencies in `package.json`
- [ ] Node.js version compatible
- [ ] Build command correct

### Runtime Failures
- [ ] Environment variables set correctly
- [ ] MongoDB connection string valid
- [ ] Firebase credentials valid
- [ ] Port configuration correct
- [ ] Start command correct

### Connection Issues
- [ ] MongoDB network access allows hosting service IP
- [ ] MongoDB cluster is active (not paused)
- [ ] MongoDB credentials correct
- [ ] Firebase project ID correct

### API Issues
- [ ] CORS configured for mobile origins
- [ ] Authentication middleware working
- [ ] Routes registered correctly
- [ ] Error handling working

## Rollback Plan

If deployment has critical issues:

### Render/Railway
- [ ] Previous deployment can be restored from dashboard
- [ ] Git commit can be reverted
- [ ] Service can be redeployed from earlier commit

### Fly.io
- [ ] Previous version can be restored: `fly releases`
- [ ] Rollback command: `fly releases rollback <version>`

## Next Steps

After successful deployment:
- [ ] Save production URL for Flutter app
- [ ] Proceed to Task 16.2 (Update Flutter app)
- [ ] Monitor logs for 24 hours
- [ ] Test from mobile app
- [ ] Set up crash reporting (Task 16.4)

## Maintenance Schedule

### Daily
- [ ] Check application logs for errors
- [ ] Monitor uptime status

### Weekly
- [ ] Review MongoDB storage usage
- [ ] Check for security updates
- [ ] Review API performance metrics

### Monthly
- [ ] Update dependencies (`npm audit fix`)
- [ ] Review and rotate credentials
- [ ] Check hosting service usage/costs
- [ ] Backup important data

## Support Resources

- **Render**: [https://render.com/docs](https://render.com/docs)
- **Railway**: [https://docs.railway.app/](https://docs.railway.app/)
- **Fly.io**: [https://fly.io/docs/](https://fly.io/docs/)
- **MongoDB Atlas**: [https://docs.atlas.mongodb.com/](https://docs.atlas.mongodb.com/)
- **Firebase**: [https://firebase.google.com/docs](https://firebase.google.com/docs)

## Notes

Add any deployment-specific notes here:

```
Deployment Date: _______________
Hosting Service: _______________
Production URL: _______________
MongoDB Cluster: _______________
Firebase Project: _______________
Deployed By: _______________
```
