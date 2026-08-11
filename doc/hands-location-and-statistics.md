# Location tracking and question statistics (removed from course-site)

The question queue ("hands") lived in course-site until it was extracted into
the separate hands app. When the local implementation was deleted, two parts of
it had no counterpart in the new app: **location tracking** and **statistics
reporting**. This document records those two parts in enough detail to rebuild
them elsewhere. The queue mechanics themselves (raising, claiming, closing,
assistant availability, the cancellation mail) are not described here — the
hands app already has them — and are mentioned only where they trigger
something described below.

Attendance stayed behind in course-site, so it is not described here either,
beyond the parts that locations touched. The division of labour after the split
is:

- **course-site** keeps attendance: one record per student per clock hour from
  ip and time, plus confirmation by a staff member on a check-in page. It has
  no notion of where anyone is sitting.
- **the hands app** owns locations, if it wants them, and everything in Part B.

Everything here is a record of what the code did, not a proposal. Where the
behaviour looked accidental, that is said so explicitly.

Vocabulary used throughout:

- **request** — one help request; the `hands` table row. Called a "hand" in the
  old code.
- **done** — the request is off the queue. Says nothing about what happened.
- **success** — a conversation actually took place. `done` without `success`
  means cancelled by the student or removed by staff.
- **duration** — `closed_at - claimed_at` in minutes, rounded; zero when the
  request was never closed. Requests that were never claimed have no duration
  and appear only in waiting-time figures.

---

## Part A — location tracking

### Purpose

A location served two purposes, and neither was about the location itself:

- **Finding the student.** An assistant picking up a request needs to know
  which table to walk to.
- **Verifying attendance.** Attendance had two halves — presence inferred from
  page loads, and presence confirmed by a human — and a location is what made
  the second half checkable: the student says where they are sitting, a staff
  member confirms that someone is really sitting there.

Attendance in course-site now keeps its confirmed half without locations: staff
check students in from a list of names. So a reimplementation is free to treat
locations purely as the first purpose — routing an assistant to a student — and
leave attendance out of it.

### Data

Per user per clock hour, an **attendance record**:

| field | meaning |
| --- | --- |
| `cutoff` | the hour, as `Time.current.beginning_of_hour`. One row per user per hour. |
| `ip` | the ip address of the last page load in that hour |
| `location` | the location the user reported, as carried onto this hour (see below) |
| `confirmed` | someone verified the user was present at that location in that hour |

On the user:

| field | meaning |
| --- | --- |
| `last_known_location` | the most recently reported location, or empty |
| `location_confirmed` | whether the current hour is confirmed |
| `last_seen_at` | timestamp of the last page load |
| `last_spoken_at` | timestamp of the last closed request (set for any close, successful or not) |
| `attendance` | eight-character sparkline of the last eight days, see "Sparkline" |

A location is a free-text string. What it is meant to contain is course
configuration: a table number by default (the setting held the noun shown to
students, defaulting to "tafelnummer"), or, for remote courses, a Zoom link
validated client-side against `https://.*zoom\.us/j/.*`.

### Where a location comes from

**Only from the student, and only through the hands widget.** There was no
other writer anywhere in the site. Two entry points, both in the navbar
dropdown:

1. The request form itself carried a location field when the course asked for
   locations. Submitting a request stored the location on the request and on
   the user.
2. A standalone check-in prompt, shown *instead of* the request form when the
   course had the "ask for location before anything else" setting on, the
   course was not in Zoom-link mode, and the user had no known location. It
   greeted the student by time of day and asked only for the location.

Writing a location (the check-in prompt path) did all of this in one
transaction:

- upsert the current hour's record and set its `location`;
- if that changed the value, set the record's `confirmed` to false and set the
  user's `last_known_location` and `location_confirmed` (false) to match.

If the location did not change, nothing was reset — re-submitting the same
table number did not undo a confirmation.

Note the asymmetry, which was probably unintended: submitting a *request* wrote
`last_known_location` on the user directly and did **not** create or update the
current hour's record, while the *check-in prompt* went through the full path
above. A reimplementation should use one path for both.

### How presence is logged

On ordinary page loads (a controller concern included by the page controller,
plus the profile controller), per user, throttled to nothing — it ran on every
qualifying request:

1. Compute `cutoff` = current hour. Load or build this hour's record; load the
   previous hour's record.
2. Set this record's `ip` from the request.
3. If the previous hour's record has a non-blank `ip` equal to this one's, copy
   the user's `last_known_location` onto this record. (Same machine, same
   place.)
4. If additionally the previous record's `location` is non-blank and equal to
   this record's `location`, copy the previous record's `confirmed` onto this
   record. Confirmation therefore carries forward hour to hour for as long as
   the student stays at the same ip and location, and lapses the moment either
   changes.
5. Save the record.
6. Update the user: `last_seen_at` = now, `location_confirmed` = this record's
   `confirmed`. If there *was* a previous record and its ip differs from this
   one, also clear `last_known_location` — moving to a different network means
   the reported spot is stale.
7. Recompute the sparkline.

Note that step 3 reads the user's `last_known_location` while step 6 may clear
it, so within a single hour the record keeps the location it was given even
after the user field is cleared.

### How confirmation happened

Confirmation is course-site's concern now, and it kept the mechanism described
here minus the location half. It is recorded in full because locations were
woven through it.

Three paths set `confirmed`:

1. **The check-in toggle** on the attendance page (below). A staff member flips
   it per student. It sets the current hour's record `confirmed` to the toggle
   value and the user's `location_confirmed` to match. It did **not** create a
   record: if the student had not loaded a page this hour, only the user field
   changed, and the hour was expected to pick the confirmation up later through
   the carry-forward rule. It did not, in fact — the carry-forward copied the
   *previous* hour's `confirmed` over it, so a check-in made before the student
   loaded a page was silently undone. Course-site fixed this when it took the
   page over: confirming now creates the record if it is missing, and
   carry-forward only ever raises a confirmation, never lowers one.
2. **A successful request close.** When a request was saved with `success`
   true, the student's presence was confirmed automatically — an assistant had
   just spoken to them, so they were demonstrably there.
3. **Carry-forward** from the previous hour, as described above.

There was a fourth, written but never enabled: a backfill that walked backwards
hour by hour from a freshly confirmed record, confirming each earlier
contiguous hour whose `ip` *and* `location` matched, stopping at the first gap
or mismatch. Both of its call sites were commented out. The intent is clear —
confirming a student at 15:00 should retroactively credit the hours they were
already sitting there — and it is worth reconsidering rather than copying the
disabled state.

### How locations expire

Three separate mechanisms, all of which cleared `last_known_location` and
`location_confirmed` on the user and left the historical records untouched:

1. **Stale-location sweep.** For every user with no attendance record in either
   the current or the previous hour, clear both fields. Throttled to at most
   once per 30 minutes by a stored timestamp setting. It ran only when a staff
   member loaded the queue page — so on a day with no staff on the queue, it
   never ran at all.
2. **End of class.** A destructive button on the attendance page ("Clear all
   confirmations") cleared both fields for every user in the current schedule
   at once, behind a confirmation dialog.
3. **Nightly job**, at 02:00, clearing both fields for every user
   unconditionally. This one survives in course-site, resetting the
   confirmation flag alone.

### The attendance page

A staff-and-admin page at `/attendance`, laid out as a floor plan:

- Students in the current schedule with status active or registered, ordered by
  location then name, grouped by `last_known_location`. Students with no
  location form their own (unlabelled) group.
- Each group renders as a box labelled with the location — representing the
  physical table — with the students seated there listed beside it.
- Per student: their name (linking to their profile in a modal), the time they
  were last seen, and the check-in toggle described above.
- The "Clear all confirmations (end of class)" button at the bottom.

The locale was forced to English on this page regardless of the user's
preference.

The page had a group filter for courses with separate TAs per group, but it was
broken: the filtering branch referenced two variables the controller never
assigned, so requesting a group raised. Only the unfiltered view worked.

### Where locations and confirmation were surfaced elsewhere

- **Navbar** — a 📌 next to the site brand when the current user's own
  attendance was confirmed. The student's own signal that the check-in
  registered.
- **Schedule overview** — per student, an "L" badge (with the location as a
  tooltip) when a location is known, and a "C" badge when confirmed. A quick
  read of who is in the room right now.
- **Student page** — the current location and whether it is confirmed, plus a
  table of today's hours with hour, location, ip and confirmed per row.
- **Attendance grid** on the student page — a week × weekday grid of coloured
  boxes over the course period, one box per day, tooltip `Mon 03 Mar: 5h(2h)`.
  Two counts per day: hours present, and hours confirmed. The colour ramp used
  green scaled by hours-present relative to the busiest day when the day had no
  confirmed hours, and blue when it had any. (The blue branch scaled its alpha
  by the raw hour count rather than the normalised value, so any day with two
  or more confirmed hours rendered fully opaque — a bug, not a design, fixed in
  course-site when the queue was removed.) The parenthesised confirmed count
  was omitted when zero.
- **Grade export** — a column counting a student's attendance records, i.e.
  hours present. Unaffected by confirmation.

### Sparkline

Independent of locations, and retained in course-site — described here only so
the grid above is not confused with it. Per user, the number of attendance
records per day over the last seven days, mapped onto the block characters
`▁▂▃▄▅▆▇█` (capped at 7), stored as a string. When displayed, it is shifted by
how many days ago the user was last seen, padding the tail with `▁`.

### What course-site kept, and what it lost

Kept: the hourly records, the sparkline, the grid, the grade-export hour count,
and confirmation in full — `attendance_records.confirmed` and a user-level flag
(renamed `attendance_confirmed`, since there is no location left for it to
refer to), still carried forward hour to hour, now on a matching ip alone.
`/attendance` survives as a plain check-in list: students in the current
schedule by name, each with a toggle and their last-seen time, plus the
end-of-class clear.

Lost: every notion of *where*. No location field, no floor plan, no "L" badge,
no location column, and no way to tell a student sitting in the lab from one
working at home — a confirmation now means only that a staff member ticked
their name.

---

## Part B — statistics reporting

All of the following was admin-only, on one page, plus per-student figures on
the user page and in the grade export.

### Per-assistant timeline, today

Which assistant was busy when, for the current day.

- **Rows**: assistants. **Source**: requests where `claimed_at` is set, `done`
  is true, and `created_at` is after the start of today, grouped by assistant.
- **Window**: from the earliest `claimed_at` in that set to the latest
  `updated_at` in it. The window is derived from the data, not from the clock,
  so an empty day renders nothing at all.
- **Segments**: one bar segment per request, offset from the previous segment's
  end by the gap to its `claimed_at`, and as wide as `updated_at - claimed_at`,
  both expressed as a percentage of the window. Tooltip: that span in whole
  minutes.
- Segments use `updated_at` as their end rather than `closed_at`. For a closed
  request these are usually the same moment, but any later touch of the row
  would stretch the bar. `closed_at` is the honest field to use.

### Load per hour, past week

Requests where `done` is true and `claimed_at` is set, `updated_at` within the
last seven days, grouped by the hour of `claimed_at`. Rendered as a grid with
one column per day present in the data and one row per hour from 8 to 23,
zero-filled. Used to see when the busy hours are, and to staff accordingly.

Note the mixed criteria: the seven-day filter is on `updated_at` while the
grouping is on `claimed_at`.

### Recent requests

A table of every request created since the start of yesterday, plus every
request still open regardless of age, newest first. Per row:

| column | content |
| --- | --- |
| created | day and time, with the question text as a tooltip |
| status | a green check when done and successful, a red cross when done and not |
| put back | a marker when the request was ever put back in the queue |
| assistant | the claiming assistant, if any |
| student | the student's name |
| waiting | `claimed_at - created_at` if claimed (with the assistant's note as tooltip); else `closed_at - created_at` if closed; else time since creation, marked as still running |
| helping | `closed_at - claimed_at` if both set; else time since `claimed_at`, marked as still running; else empty |

Durations are rendered in words ("about 5 minutes"), not exact figures.

### Per-student figures

- **Counters on the user**: number of successful requests, and total minutes
  spent being helped. Maintained on every save of a request: when `success`
  flips to true, increment the count by one and the minutes by the request's
  duration; when it flips to false, decrement both by the same. Duration is
  `closed_at - claimed_at` in minutes, zero if never closed — so a request
  marked successful before being closed contributed zero minutes and could
  never be corrected afterwards, since the counter only moved on the `success`
  flip. Storing the figures as counters rather than deriving them was a
  performance decision for the schedule overview; deriving them is simpler and
  correct.
- **Both counters are shown per student in the schedule overview**, as
  "N hands, M mins".
- **History list on the student page**: for each *successful* request, its id,
  `claimed_at`, minutes taken, and the assistant's name. Requests with no
  `claimed_at` or no `closed_at` were skipped.
- **Grade export**: a column counting successful requests per student.

### Non-statistical bookkeeping worth knowing about

Every save of a request also appended a log note to the student's note stream,
recording the changed attributes and their new values, attributed to the
student and flagged as a log entry. This was the audit trail for "what happened
to this request", and it is the only place where the free-text `evaluation`,
`note` and `progress` fields ended up being read back.

---

## Appendix — user-facing text

The full `hands:` locale subtree as it stood, both languages, verbatim. Only
the check-in and location strings are strictly in scope for this document, but
the subtree is small and would otherwise be lost. The `prompts:` list was
sampled to suggest a conversation opener to an assistant approaching a student
who had not asked anything; the commented-out entries are as they were.

### English

```yaml
hands:
    assistance: Assistance
    staff_are_currently_available:
        one: One member of staff is available
        other: "%{count} staff are currently available"
    request_assistance_in_class: "Request assistance in class!"
    good_morning: "Good morning"
    good_afternoon: "Good afternoon"
    good_evening: "Good evening"
    good_night: "Good night"
    lets_check_you_in: "Let's check you in."
    entering_location: "Entering your %{location_type} helps to register attendance"
    save_my_location: "Save my location"
    summary: "Summary"
    location: "Location"
    briefly_summarize: "Provide a summary of what you would like to discuss"
    subject: "About which assignment?"
    enter_location: "Enter your location"
    ask_for_assistance: "Ask for assistance"
    posting_question: "Aanvraag wordt verstuurd..."
    you_are_number_1_in_line: "You are number %{number} in line."
    wait_is_over: "The wait is over!"
    is_looking_to_help_you: "%{name} is looking to assist you right now."
    cancel_request: "Cancel request"
    link: "Provide your Zoom link"
    in_line: "We ask that you wait a bit because you were helped just recently and it's quite busy!"

    prompts:
        - "What project are you currently working on, and how can I assist you?"
        - "Have you encountered any challenges in your coding tasks today?"
        # - "What programming language are you most comfortable with and why?"
        - "Is there a particular programming concept you'd like to explore further?"
```

The English `posting_question` string was Dutch. Left as found.

### Dutch

```yaml
hands:
    assistance: Assistentie
    staff_are_currently_available:
        one: Eén medewerker beschikbaar
        other: "%{count} medewerkers beschikbaar"
    request_assistance_in_class: "Zet jezelf hier in de rij voor een vraag:"
    good_morning: "Goedemorgen"
    good_afternoon: "Goedemiddag"
    good_evening: "Goedenavond"
    good_night: "Goedenavond"
    lets_check_you_in: "Check jezelf in."
    entering_location: "Geef je %{location_type}"
    save_my_location: "Sla mijn locatie op"
    summary: "Samenvatting"
    location: "Locatie"
    briefly_summarize: "Geef aan wat je wil bespreken"
    subject: "Over welke opdracht gaat het?"
    enter_location: "Vermeld je huidige %{type}"
    ask_for_assistance: "Vraag om assistentie"
    posting_question: "Aanvraag wordt verstuurd..."
    you_are_number_1_in_line: "Je bent nummer %{number} in de wachtrij."
    wait_is_over: "Het wachten is voorbij!"
    is_looking_to_help_you: "%{name} is op dit moment naar je op zoek om je te assisteren."
    in_line: Je staat even in de wacht omdat je kort geleden geholpen bent, en het is nogal druk!
    cancel_request: "Annuleren"
    link: "Geef je Zoom-link"

    prompts:
        - "Aan welk project werk je momenteel en hoe kan ik je helpen?"
        - "Ben je vandaag tegen uitdagingen aangelopen bij je programmeertaken?"
        # - "Met welke programmeertaal voel je je het meest vertrouwd en waarom?"
```

`entering_location` takes `location_type` while `enter_location` takes `type`;
the two keys were used in different places and never unified.

---

## Not carried over

Implementation details of the old version that a reimplementation should not
copy:

- The polling transport. The student widget re-fetched a `.js.erb` fragment on
  a timer and replaced the dropdown's innerHTML. The hands app uses Action
  Cable.
- The counters on the user. Derive the figures instead.
- The SQLite-specific `JulianDay` arithmetic used to sum durations in SQL.
- Reading `updated_at` where `closed_at` is meant, in the timeline chart.
- The stale-location sweep running as a side effect of a staff page load. If
  locations expire, that belongs in a scheduled job — there already was one,
  nightly, doing a blunter version of the same thing.
