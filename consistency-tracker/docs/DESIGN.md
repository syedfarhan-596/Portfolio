# Consistency Tracker — Design & Plan

> A local-only Android app that turns *your* real daily routine into a system
> that makes consistency obvious, attractive, easy, and satisfying.
> No account, no cloud, no data leaving your phone.

---

## 1. Philosophy: two tracks, not one list

The single biggest mistake most habit apps make is treating "drink water" and
"learn DSA" as the same kind of thing. They are not.

| | **Track A — Maintenance** | **Track B — Growth** |
|---|---|---|
| Examples | soaked dry fruits, walk, night creams, prayer, water | DSA, development, reading, projects, learning |
| Goal | **show up** (binary: done / skipped) | **make progress** (you're building skill) |
| Cadence | **daily & automatic** | **2 focus days/week + light daily touch** |
| Tracked as | a checkbox + streak | a score + units done (problems, modules, chapters) |
| Psychology | habit formation (automaticity) | deliberate practice + spacing |

This is the core of the app. Everything else is built on top of it.

### Why your "weekly" idea is right *here* but needed a fix

Your instinct — *"doing it every day might not be possible, so break it into
2 days a week"* — is correct for **growth skills**, because forcing DSA + dev +
reading + project every single day is what was making you miss them. But a pure
7-day gap is too long while you're still grasping fundamentals (the forgetting
curve resets each time). So the model is:

- **2 "deep days" per week per skill** — the real work, where you finish a unit
  (a DSA problem set, a dev module, a book chapter).
- **An optional 2-minute "keep-warm" touch** on other days so context doesn't
  evaporate between deep days.
- A skill can be flagged **PUSH** (learning phase, higher frequency) or
  **MAINTAIN** (already fluent, lower frequency). Don't try to PUSH three things
  at once — sequence them.

---

## 2. Your life, mapped into the app

The app ships pre-seeded with *your* routine as two **habit stacks** (chains),
so it feels like yours from day one. (Atomic Habits: habit stacking =
"After [current habit], I will [new habit].")

### ☀️ Morning stack
1. Wake up *(anchor)*
2. Fresh up
3. Get ready
4. Eat soaked dry fruits 🥜  *(maintenance, daily)*
5. Breakfast
6. Office *(anchor — chain ends)*

### 🌙 Evening stack
1. Come home *(anchor)*
2. Chill break till 8:00
3. Prayer @ 8:30 🕌  *(maintenance, daily)*
4. Dinner
5. Walk 🚶  *(maintenance, daily — currently often missed)*
6. **Focus block: 2 growth tasks** 📚  *(DSA / dev / reading / project — driven by Track B schedule)*
7. Night-care creams 🧴  *(maintenance, daily)*
8. Soak dry fruits for tomorrow 🌰  *(maintenance, daily)*
9. Chess — 2–3 games ♟️  *(your reward / streak anchor — see below)*
10. Sleep *(anchor — chain ends)*

> Note how chess sits at the **end** as the reward. That's *temptation bundling*
> (Atomic Habits Law 2) — we keep it there deliberately. The hard stuff
> (walk + focus block) is "paid off" by the thing you already love.

### The chess streak insight (your "70" streak)
The reason chess sticks is the **streak you don't want to break** — that's the
strongest motivator you already have. We replicate that *satisfaction loop* for
the habits you currently miss (walk, focus block), but with a humane twist so
one bad day doesn't nuke your motivation (see "Never miss twice" below).

---

## 3. Atomic Habits — the 4 Laws baked into the UI

The app isn't *about* Atomic Habits; it's *built out of* its four laws.

### Law 1 — Make it **Obvious** (cue)
- **Anchored reminders**: notifications fire relative to your routine, not random
  clock times — "After dinner → time to walk", "8:25 → prayer in 5".
- **Implementation intentions**: every habit stores a sentence —
  *"I will [walk] at [8:50pm] after [dinner]."*
- **Today timeline**: home screen shows your day as the stack, in order, with the
  next action highlighted. No hunting.

### Law 2 — Make it **Attractive** (craving)
- **Temptation bundling**: chess stays locked as the *last* step after the focus
  block, so the thing you crave pulls the thing you avoid.
- **Identity statements**: each habit ties to who you're becoming —
  *"I am someone who learns every day."* You check off votes for that identity.
- **Beautiful, calm UI** + anticipation: streak flames, the green grid filling in.

### Law 3 — Make it **Easy** (response)
- **One-tap logging.** Done is a single tap. No forms.
- **2-minute rule mode**: every habit has a minimum version ("read 1 page",
  "1 DSA problem"). On low-energy days you log the 2-min version and *still keep
  the streak* — the goal is to never break the chain, not to be a hero.
- **Friction design**: pre-seeded routine, smart defaults, sensible reminder times.

### Law 4 — Make it **Satisfying** (reward)
- **GitHub-style green heatmap** — immediate visual proof of consistency.
- **Streaks** with celebration animation when you log.
- **Weekly score** + progress bars per skill — your "every week progress".
- **Never miss twice**: miss one day and the app reframes, not punishes —
  *"One miss is an accident. Let's not miss tomorrow."* Optional **streak freeze**
  / planned rest days so life doesn't destroy months of momentum.

---

## 4. Feature list

### Core (must-have for v1)
- ✅ Two-track model: maintenance habits + growth skills
- ✅ Habit stacks (your morning & evening chains, reorderable)
- ✅ One-tap daily logging + 2-minute-rule fallback
- ✅ Streaks per habit, with "never miss twice" + optional freeze
- ✅ **GitHub-style contribution heatmap** (green grid) — per habit and overall
- ✅ Weekly score + per-skill progress (units done vs target)
- ✅ Smart anchored notifications / reminders
- ✅ Stats dashboard: today, this week, this month, all-time
- ✅ Skill scheduler: assign DSA/dev/reading to 2 days a week each
- ✅ 100% local storage (Room/SQLite) — no login, no network permission

### Things I'd add if I were building it for myself
- 🔁 **PUSH vs MAINTAIN phase** per skill — focus your learning energy on one
  thing at a time instead of dabbling in everything.
- 📝 **Weekly review screen** — a 60-second Sunday retro: what worked, what to
  adjust, set next week's focus. (This is the single highest-leverage feature
  for *actually improving* vs just tracking.)
- 🆔 **Identity dashboard** — see the identities you're voting for and your
  "vote count" (e.g. "Learner: 142 votes").
- 🧊 **Streak freeze / planned off-days** — humane streaks (the Duolingo trick),
  so a sick day or travel doesn't demoralize you.
- 💧 **Quantified habits** — water as glasses toward 3–4 L, steps toward 10k
  (manual entry, optional later Health Connect integration).
- 🏠 **Home-screen widget** — today's habits + current streak, one glance.
- 🌗 **Dark mode** + Material You dynamic color (matches your wallpaper).
- 💾 **Backup & restore (export/import JSON)** — critical for local-only: never
  lose your history when you change phones. *(Local-only's one weakness is
  device loss; an export file fixes it without any cloud.)*
- 🔔 **Smart nudge for missed items** — gentle end-of-day "you still have time
  for your walk" instead of guilt the next morning.
- 🎉 **Celebration micro-animations** on completion (dopamine, Law 4).

### Deliberately NOT in v1 (avoid burden / scope creep)
- ❌ No social feed, no friends, no sharing (you said: not too burdened, local).
- ❌ No accounts / cloud sync.
- ❌ No over-gamified points economy — score stays simple and honest.

---

## 5. Screens (UX map)

1. **Today** (home) — timeline of today's stack, next action highlighted,
   one-tap complete, today's mini-heatmap dot + streak flames.
2. **Habits** — manage maintenance habits & stacks (reorder, edit anchors,
   2-min version, identity statement, reminder).
3. **Skills** — Track B: each skill with PUSH/MAINTAIN, weekly target, deep-day
   schedule, units logged, progress bar.
4. **Stats / Insights** — the big **green heatmap**, streaks, weekly score,
   per-skill trends, consistency % .
5. **Weekly Review** — Sunday retro + set next week's focus.
6. **Settings** — notifications, theme, backup/restore, streak-freeze rules.

Design language: **Material 3 (Material You)**, clean, generous spacing, calm
palette, the green grid as the signature visual. Smooth, quiet animations.

---

## 6. Tech stack (recommended)

Native Android, because you want local-only, great UI, reliable notifications,
and a home-screen widget:

| Concern | Choice | Why |
|---|---|---|
| Language | **Kotlin** | Modern, the Android standard |
| UI | **Jetpack Compose + Material 3** | Beautiful, fast to build, Material You |
| Local DB | **Room** (SQLite) | Robust local persistence, no server |
| Prefs | **DataStore** | Settings/flags |
| Reminders | **WorkManager + AlarmManager** | Reliable scheduled notifications |
| Widget | **Glance** | Compose-style home-screen widget |
| Architecture | **MVVM** + repository | Clean, testable |
| Min SDK | **API 26 (Android 8)** | Covers ~95%+ devices, modern APIs |

> Alternative: **Flutter** if you ever want iOS too. For "Android, local,
> beautiful, native widgets," Kotlin + Compose is the cleaner fit. Recommended.

---

## 7. Data model (first cut)

```
Habit
  id, name, icon, color
  track: MAINTENANCE | SKILL
  identityStatement: "I am someone who…"
  cue / anchorText: "after dinner"
  reminderTime, reminderEnabled
  twoMinuteVersion: "read 1 page"
  // SKILL-only:
  phase: PUSH | MAINTAIN
  weeklyTarget: Int            // e.g. 2 deep days
  scheduledDays: Set<DayOfWeek>
  unitName: "problem" | "module" | "chapter"

HabitStack            // a chain (Morning / Evening)
  id, name, orderedHabitIds[]

HabitLog
  id, habitId, date
  status: DONE | TWO_MIN | SKIPPED | FROZEN
  value: Int?          // units done / glasses / minutes
  note: String?

StreakState           // per habit: current, longest, freezes left
WeeklyReview          // weekNumber, wins, adjustments, nextFocus
```

The green heatmap is derived from `HabitLog` (count of DONE/TWO_MIN per day →
color intensity), exactly like GitHub contributions.

---

## 8. Build phases

1. **Phase 0 — Scaffold**: Android Studio project, Compose, Room, theme, nav.
2. **Phase 1 — Core loop**: habits + one-tap logging + Today screen + streaks.
3. **Phase 2 — The green heatmap + stats dashboard.**
4. **Phase 3 — Skills track**: scheduler, PUSH/MAINTAIN, weekly score.
5. **Phase 4 — Notifications** (anchored reminders) + 2-minute rule.
6. **Phase 5 — Polish**: widget, weekly review, backup/restore, animations,
   dark mode, pre-seeded routine.

---

## 9. Open decisions (for you)

1. **Tech stack** — confirm Kotlin + Jetpack Compose (recommended) vs Flutter.
2. **Where the code lives** — this `consistency-tracker/` folder in the Portfolio
   repo (current plan) vs a brand-new dedicated repo.
3. **App name** — placeholder; pick something that reinforces identity
   (e.g. "Streakly", "Daily Votes", "Chain", "Consistent").
