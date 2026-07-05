import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import * as jose from "https://deno.land/x/jose@v5.2.4/index.ts"

serve(async (req) => {
  // Allow CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      }
    })
  }

  try {
    const payload = await req.json()
    console.log('Webhook payload received:', JSON.stringify(payload))

    // Check if event is an INSERT operation
    if (payload.type !== 'INSERT') {
      return new Response(JSON.stringify({ message: `Ignored event type: ${payload.type}` }), {
        headers: { 'Content-Type': 'application/json' },
        status: 200,
      })
    }

    const event = payload.record
    if (!event || !event.title) {
      return new Response(JSON.stringify({ error: 'Invalid event record payload' }), {
        headers: { 'Content-Type': 'application/json' },
        status: 400,
      })
    }

    // Retrieve Firebase Service Account JSON key from environment variables
    const serviceAccountEnv = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
    if (!serviceAccountEnv) {
      console.error('FIREBASE_SERVICE_ACCOUNT secret is missing')
      return new Response(JSON.stringify({ error: 'FIREBASE_SERVICE_ACCOUNT secret is not configured' }), {
        headers: { 'Content-Type': 'application/json' },
        status: 500,
      })
    }

    const serviceAccountJson = JSON.parse(serviceAccountEnv)
    const projectId = serviceAccountJson.project_id
    const clientEmail = serviceAccountJson.client_email
    const privateKeyHex = serviceAccountJson.private_key

    if (!projectId || !clientEmail || !privateKeyHex) {
      console.error('FIREBASE_SERVICE_ACCOUNT secret is malformed')
      return new Response(JSON.stringify({ error: 'FIREBASE_SERVICE_ACCOUNT secret is malformed' }), {
        headers: { 'Content-Type': 'application/json' },
        status: 500,
      })
    }

    // Generate OAuth2 access token using the jose library
    console.log('Signing Google OAuth2 JWT assertion...')
    const privateKey = await jose.importPKCS8(privateKeyHex, 'RS256')
    const jwt = await new jose.SignJWT({
      iss: clientEmail,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      exp: Math.floor(Date.now() / 1000) + 3600,
      iat: Math.floor(Date.now() / 1000),
    })
      .setProtectedHeader({ alg: 'RS256' })
      .sign(privateKey)

    console.log('Requesting OAuth2 access token from Google...')
    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: jwt,
      }),
    })

    if (!tokenResponse.ok) {
      const errorText = await tokenResponse.text()
      console.error('Google OAuth2 error response:', errorText)
      return new Response(JSON.stringify({ error: `Failed to authenticate with Google: ${errorText}` }), {
        headers: { 'Content-Type': 'application/json' },
        status: 500,
      })
    }

    const tokenData = await tokenResponse.json()
    const accessToken = tokenData.access_token

    // Dispatch FCM HTTP v1 notification to the "events" topic
    console.log(`Sending push notification for event "${event.title}" to "events" topic...`)
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`
    
    const fcmResponse = await fetch(fcmUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        message: {
          topic: 'events',
          notification: {
            title: 'New Event Added!',
            body: event.title,
          },
          data: {
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
            event_id: event.id,
          },
          android: {
            notification: {
              click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
          },
          apns: {
            payload: {
              aps: {
                category: 'NEW_EVENT',
              },
            },
          },
        },
      }),
    })

    const fcmResult = await fcmResponse.json()
    console.log('FCM dispatch response:', JSON.stringify(fcmResult))

    return new Response(JSON.stringify({ success: true, fcmResult }), {
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      status: fcmResponse.status,
    })

  } catch (error) {
    console.error('Exception occurred in send-event-notification:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      status: 500,
    })
  }
})
