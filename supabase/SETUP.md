# Hawi Motors — marketplace backend setup

This folder contains the first backend foundation for a real multi-user marketplace.

## Create the Supabase project
1. Open https://supabase.com and create a free account/project.
2. Choose a strong database password and keep it private.
3. In the dashboard, open SQL Editor → New query.
4. Copy all of schema.sql into the editor and run it.
5. Open Project Settings → API (or Data API) and copy the Project URL and publishable/anon key.
6. Keep those two values ready for the next integration step. Never share the database password or service-role/secret key.

## What the schema provides
- Seller profiles and authenticated accounts.
- Car listings with pending/approved/rejected/sold moderation states.
- Listing photo metadata and a car-photos storage bucket.
- Row-level security for seller-owned records and public approved listings.

## Launch safeguards
- New listings default to pending and must be reviewed before public display.
- The current homepage still contains labelled demo cars until the frontend is connected.
- Proposed KSh 500 featured and KSh 3,000 dealer prices are not active payment products.
- Buyer-to-seller vehicle payments should go directly to the seller; Hawi Motors collects only its own advertising fees.
- M-Pesa automation requires a suitable merchant shortcode and Daraja credentials. Never put Daraja secrets or service-role keys in browser code.

## Next step
After creating the project and running schema.sql, share only the Project URL and publishable/anon key in this chat. Never provide your database password, service-role key, or Daraja secret.