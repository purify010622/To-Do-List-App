# Backend Setup Instructions

## Prerequisites

- Node.js 18+ installed
- MongoDB installed locally OR MongoDB Atlas account
- Firebase project with Admin SDK credentials

## Installation Steps

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Configure Environment Variables

Create a `.env` file in the backend directory:

```bash
cp .env.example .env
```

Edit `.env` and configure:

**MongoDB Configuration:**
- For local MongoDB: `MONGODB_URI=mongodb://localhost:27017/todo-app`
- For MongoDB Atlas: Get connection string from Atlas dashboard

**Firebase Configuration:**
1. Go to Firebase Console → Project Settings → Service Accounts
2. Click "Generate New Private Key"
3. Copy the values to your `.env` file:
   - `FIREBASE_PROJECT_ID`: Your project ID
   - `FIREBASE_PRIVATE_KEY`: The private key (keep the quotes and newlines)
   - `FIREBASE_CLIENT_EMAIL`: The client email

**CORS Configuration:**
- Update `ALLOWED_ORIGINS` to match your Flutter app's origins
- Default: `http://localhost:*,capacitor://localhost,ionic://localhost`

### 3. Start the Server

**Development mode (with auto-reload):**
```bash
npm run dev
```

**Production mode:**
```bash
npm start
```

The server will start on `http://localhost:3000` (or the PORT specified in .env)

### 4. Verify Installation

Check the health endpoint:
```bash
curl http://localhost:3000/health
```

Expected response:
```json
{
  "status": "ok",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

## Running Tests

```bash
npm test
```

For test coverage:
```bash
npm test -- --coverage
```

## API Endpoints

### Authentication
- `POST /api/auth/verify` - Verify Firebase token

### Tasks (Requires Authentication)
- `GET /api/tasks` - Get all tasks
- `POST /api/tasks/sync` - Sync tasks
- `PUT /api/tasks/:id` - Update task
- `DELETE /api/tasks/:id` - Delete task

### Authentication Header Format
```
Authorization: Bearer <firebase-id-token>
```

## Rate Limiting

- General API endpoints: 100 requests per 15 minutes per user
- Auth endpoints: 10 requests per 15 minutes per IP

## Troubleshooting

### MongoDB Connection Issues
- Ensure MongoDB is running: `mongod --version`
- Check connection string format
- For Atlas: Whitelist your IP address

### Firebase Authentication Issues
- Verify Firebase credentials in `.env`
- Ensure private key has proper newline characters (`\n`)
- Check Firebase project is active

### Port Already in Use
- Change PORT in `.env` file
- Or kill the process using the port

## Production Deployment

### Recommended Free Hosting Options
1. **Render** (render.com)
2. **Railway** (railway.app)
3. **Fly.io** (fly.io)

### MongoDB Atlas Setup
1. Create free cluster at mongodb.com/cloud/atlas
2. Create database user
3. Whitelist IP addresses (0.0.0.0/0 for all)
4. Get connection string and update `.env`

### Environment Variables for Production
Ensure all environment variables are set in your hosting platform:
- `NODE_ENV=production`
- `MONGODB_URI`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_PRIVATE_KEY`
- `FIREBASE_CLIENT_EMAIL`
- `ALLOWED_ORIGINS`

## Security Notes

- Never commit `.env` file to version control
- Use strong MongoDB credentials
- Keep Firebase private key secure
- Enable HTTPS in production
- Regularly rotate credentials
- Monitor rate limit violations

## Support

For issues or questions, refer to:
- Express.js documentation: expressjs.com
- MongoDB documentation: docs.mongodb.com
- Firebase Admin SDK: firebase.google.com/docs/admin/setup
