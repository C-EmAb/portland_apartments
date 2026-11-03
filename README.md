# Portland apartment finder

A one-page website for paging through apartment listings, plus the daily task that fills it.

How it fits together: a Cowork task checks the property management sites each morning and saves matches to a Supabase database. A small website hosted on GitHub Pages reads that database and shows the listings as a slideshow called Available Listings, plus a map and a page of listings you've suppressed.

## What's in this folder

- `index.html`: the website.
- `config.js`: where your Supabase address and key go.
- `supabase/schema.sql`: creates the database tables, including the one that stores your saves and suppressions. Includes one starter listing (The Tristan) so you can see the site work right away. Safe to run again: it only adds what's missing.
- `cowork/daily-task.md`: the instructions for the daily Cowork task.

## Setup

### 1. Create a Supabase project
This is called **provisioning a database**. It's where the listings live between daily runs.

1. Sign up or log in at supabase.com and create a new project. Any name works, e.g. `apartment-finder`.
2. Pick the West US region (closest to you) and save the database password somewhere safe. You won't need it for this setup, but you'll want it later.

### 2. Create the tables
This is called **running a migration**: setting up the database's structure. It also turns on access rules (called **Row Level Security**) so the website can read listings but nobody can change them from the website.

1. In your project, open **SQL Editor** from the left sidebar and start a new query.
2. Paste in everything from `supabase/schema.sql` and click **Run**. You should see "Success."

Already ran an earlier version? Run the new file again the same way. It adds the new pieces without touching your listings.

### 3. Copy your project's address and public key
The website needs these to find your database. This is called **configuring the client**.

1. In the project's settings, find the API keys section.
2. Copy the **Project URL** (looks like `https://abcdefghijkl.supabase.co`).
3. Copy the **publishable** key (starts with `sb_publishable_`). Older projects call it the **anon** key, which starts with `eyJ`.
4. Open `config.js` in any text editor and paste both in between the quotes.

Only ever use the publishable/anon key here. The **secret** or **service_role** key can change your data and must never go on a website.

### 4. Create a GitHub repository
A **repository** ("repo") is a folder on GitHub that stores the website's files and keeps a history of every change.

1. Sign up or log in at github.com and click **New repository**.
2. Name it, e.g. `apartment-finder`, and choose **Public**. Free GitHub Pages hosting needs a public repo.
3. Click **Create repository**.

### 5. Upload the files
Saving files to the repo is called **committing**. Each commit is a saved snapshot you can go back to.

1. In the new repo, click **uploading an existing file** (or **Add file → Upload files**).
2. Drag in `index.html`, `config.js` (with your details filled in), and the `supabase` and `cowork` folders.
3. Click **Commit changes**.

### 6. Turn on GitHub Pages
This is called **deploying**: putting the site online.

1. In the repo, go to **Settings → Pages**.
2. Under "Build and deployment," set the source to **Deploy from a branch**, pick **main** and **/ (root)**, and click **Save**.
3. After a minute or two, the page shows your site's address, something like `https://yourname.github.io/apartment-finder/`. Open it. You should see The Tristan.

### 7. Turn on sign-in
This is called **setting up authentication**. Signing in is what lets the site save your suppressions to the database, so they follow you between your phone and laptop. You'll sign in with a link emailed to you (a **magic link**), with no password needed.

1. In Supabase, open **Authentication** from the left sidebar and find the **URL Configuration** settings.
2. Set **Site URL** to your GitHub Pages address from step 6 (e.g. `https://yourname.github.io/apartment-finder/`), and add the same address under **Redirect URLs**. This tells Supabase where to send you back after you click the emailed link.
3. On your site, click **Sign in**, enter your email, and open the link from the email **on the same device**. Repeat once on each device you use.
4. Optional but tidy: once you're signed in, go to Authentication's sign-in settings and turn off new sign-ups, so nobody else can create an account. Your own sign-in keeps working. Other people could never see or change your suppressions anyway.

### 8. Set up the daily task in Cowork
This is the **scheduled job** that keeps the listings fresh.

1. In Claude Cowork, connect the **Supabase** connector and make sure **Claude in Chrome** is on.
2. Put `Copy_of_Copy_of_Apartments.xlsx` in a folder Cowork can access.
3. Create a new scheduled task that runs daily, early morning. Paste in the instructions from `cowork/daily-task.md`, with `YOUR_PROJECT_REF` replaced by your project ID (the part before `.supabase.co`).
4. Run it once by hand and watch the first run. Expect to tweak a few site instructions after seeing what it struggles with.

## Using the site

- **Available Listings** is a slideshow, one listing per slide. Use **Previous listing** / **Next listing** or the arrow keys to move between listings, and the arrows on the photo (or swipe on your phone) to flip through its photos.
- Listings don't repeat or pile up day to day. Each one stays in the deck until it's taken down or shows "Application pending" on the company's site, then it drops off after the next daily check. New ones get a **New** badge on the day they're found.
- **Suppress for one month** hides a listing until a month from today, then it comes back if it's still listed. **Suppress permanently** hides it for good. Both show up on the **Suppressed** page with a link to the listing and a **Reinstate** button. If a suppressed unit gets reposted under a new link at the same address, it stays hidden.
- **Refine** narrows what's in the slideshow and on the map: max rent, bedrooms, area (N, NE, SE, NW, SW, S), must-haves that have to be confirmed (washer/dryer in unit, parking, 2nd floor or higher), company, and which listings to show (new, strong matches, worth a check, saved). Your refinements are remembered on each device.
- **Strong matches** have an in-unit washer/dryer, parking, and a clearly in-range address. **Worth a check** passed your requirements but has something unconfirmed; the yellow lines on each slide say what.
- **Map** shows every listing in your current refinements. Green pins are strong matches, yellow are worth a check, and the dashed line is 82nd Ave. Click a pin, then **View in Available Listings** to jump to that slide.
- **Save** keeps a listing in the Saved view. Save and suppress need you to be signed in.

## Good to know

- The site and its listings can be seen by anyone who has the link. It only contains public listing info. Your saves and suppressions are only visible to you when signed in.
- Map pins come from the listing's own coordinates when the daily task finds them; otherwise the site looks up the address with OpenStreetMap's free address lookup, about one per second, and remembers the result on that device. A brand-new batch can take a few seconds to fill in.
- Photos load straight from the property management sites. If one shows blank, the company has removed or blocked the image; the listing link still works.
- When a listing disappears from its company's site, it drops off your site the next day.
- To change the site later (colors, more filters), edit `index.html` in GitHub (pencil icon → **Commit changes**). The live site updates within a minute or two.
