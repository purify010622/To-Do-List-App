# Todo App Backend API

Backend API for the Todo App with offline sync functionality.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Create `.env` file from `.env.example`:
```bash
cp .env.example .env
```

3. Configure environment variables in `.env`:
   - Set MongoDB connection string
   - Add Firebase Admin SDK credentials
   - Configure CORS allowed origins

4. Start the server:
```bash
# Development mode with auto-reload
npm run dev

# Production mode
npm start
```

## API Endpoints

### Authentication
- `POST /api/auth/verify` - Verify Firebase token

### Tasks
- `GET /api/tasks` - Get all tasks for authenticated user
- `POST /api/tasks/sync` - Sync tasks (upload/download)
- `PUT /api/tasks/:id` - Update specific task
- `DELETE /api/tasks/:id` - Delete specific task

## Testing

Run tests:
```bash
npm test
```

## Environment Variables

See `.env.example` for required environment variables.

## Deployment

### Quick Start

For detailed deployment instructions, see:
- **[DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)** - Complete deployment walkthrough
- **[MONGODB_ATLAS_SETUP.md](./MONGODB_ATLAS_SETUP.md)** - MongoDB Atlas configuration
- **[DEPLOYMENT_CHECKLIST.md](./DEPLOYMENT_CHECKLIST.md)** - Pre-flight checklist

### Deployment Options

This backend can be deployed to:
- **Render** (recommended) - Free tier with auto-deploy from GitHub
- **Railway** - Free tier with $5/month credit
- **Fly.io** - Free tier with CLI deployment

### Quick Deploy to Render

1. Push code to GitHub
2. Sign up at [render.com](https://render.com)
3. Create new Web Service from your repository
4. Set root directory to `backend`
5. Add environment variables (see DEPLOYMENT_GUIDE.md)
6. Deploy!

Your API will be live at: `https://your-app.onrender.com`

### Configuration Files

- `render.yaml` - Render configuration
- `railway.json` - Railway configuration
- `fly.toml` - Fly.io configuration

### Production Checklist

Before deploying:
- [ ] MongoDB Atlas cluster created
- [ ] Firebase Admin SDK credentials obtained
- [ ] Environment variables configured
- [ ] CORS origins updated for production
- [ ] Health endpoint tested

After deploying:
- [ ] Test health endpoint: `curl https://your-app.com/health`
- [ ] Verify MongoDB connection in logs
- [ ] Test API endpoints with valid token
- [ ] Update Flutter app with production URL

## Monitoring

### Health Check

```bash
curl https://your-deployed-url.com/health
```

Expected response:
```json
{"status":"ok","timestamp":"2024-01-01T00:00:00.000Z"}
```

### Logs

**Render**: View in dashboard under "Logs" tab
**Railway**: Run `railway logs`
**Fly.io**: Run `fly logs`

## Security

- All endpoints use HTTPS
- Firebase token authentication required
- Rate limiting: 100 requests per 15 minutes
- CORS configured for mobile app origins
- Input validation on all endpoints
- Helmet security headers enabled

## Support

For deployment issues, consult:
1. DEPLOYMENT_GUIDE.md troubleshooting section
2. Hosting service documentation
3. MongoDB Atlas documentation
4. Firebase Admin SDK documentation
