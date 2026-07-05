-- SQL Trigger to call the Supabase Edge Function whenever a new event is added.
-- Paste this script into the Supabase SQL Editor (Dashboard -> SQL Editor).

-- IMPORTANT: 
-- Replace 'YOUR_PROJECT_REF' with your actual Supabase Project Reference ID (e.g. pzewonetjzuqxqyhsxnz).
-- Replace 'YOUR_SUPABASE_ANON_KEY' with your actual Supabase anon public key.

CREATE OR REPLACE FUNCTION public.handle_new_event_notification()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM
    net.http_post(
      url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-event-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer YOUR_SUPABASE_ANON_KEY'
      ),
      body := jsonb_build_object(
        'type', 'INSERT',
        'table', 'events',
        'record', row_to_json(NEW)
      )
    );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger on the events table
DROP TRIGGER IF EXISTS trigger_on_new_event_notification ON public.events;
CREATE TRIGGER trigger_on_new_event_notification
AFTER INSERT ON public.events
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_event_notification();
