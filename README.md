# Grove Reading Log 
**iOS Application | SwiftUI | Firebase | Google Books API**

Grove Reading Log is a full-featured iOS reading tracker designed to help users organize their books, track reading progress, and gain meaningful insights into their reading habits. The app supports authenticated, user-specific data and dynamically updates content using real APIs—no hardcoded demo data.

---
## App Demo

A short walkthrough demonstrating authentication, library management, reading analytics, and UI flow:

 https://www.youtube.com/watch?v=lFk5TdH2WQ8

## Features

### Library Management
- Add books via **Google Books API** search or manual entry
- Organize books into shelves:
  - Currently Reading
  - Wishlist
  - Finished
  - Didn’t Finish
- Rate books and view detailed book information
- Prevents duplicate books per user

### Personalized Home Dashboard
- “Continue Reading” carousel based on active books
- Weekly reading snapshot (pages, minutes, sessions)
- Trending and recommendation sections powered by live API data
- Content adapts per user and updates in real time

### Reading Statistics
- Weekly and yearly reading views
- Reading goals with progress visualization
- Reading streaks and session tracking
- Pages read, minutes spent, and session counts

### Profile & Boards
- Authenticated user profile
- Boards feature to curate and group books (Pinterest-style)
- Profile stats update automatically as reading activity changes

### Authentication & Persistence
- **Firebase Authentication (Google Sign-In)**
- User-specific data storage (each account sees only their own library, stats, and boards)
- Data persists across app launches and sessions

---

## Tech Stack

- **Language:** Swift  
- **Framework:** SwiftUI  
- **Architecture:** MVVM-style state management  
- **Persistence:** SwiftData  
- **Authentication:** Firebase Auth (Google Sign-In)  
- **APIs:** Google Books API  
- **IDE:** Xcode  

---

## What I Built & Learned

- Designed a multi-tab SwiftUI app with consistent visual language
- Integrated third-party authentication and external APIs
- Managed user-scoped data models with SwiftData
- Implemented debounced API search for performance
- Built reusable UI components (cards, chips, rating stars)
- Handled async data loading and error states gracefully
- Debugged complex navigation and state propagation issues

---

## Setup Notes (For Reviewers)

This repository **intentionally excludes**:
- `GoogleService-Info.plist`
- Firebase API keys and secrets

To run the app locally:
1. Create a Firebase project
2. Enable **Google Authentication**
3. Add your own `GoogleService-Info.plist`
4. Run in Xcode

The app architecture is complete and production-ready; sensitive credentials are omitted for security.

---

## Future Improvements

- Cloud sync across multiple devices (Firestore / CloudKit)
- Expanded analytics (reading trends, averages, comparisons)
- Accessibility enhancements (VoiceOver, Dynamic Type)
- Social features (shared boards, recommendations)
- App Store deployment

---

## License

Copyright © 2026 Valerie Pena  

Licensed under the Apache License, Version 2.0.  
You may obtain a copy of the License at:

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software  
distributed under the License is provided on an **"AS IS"** basis,  
without warranties or conditions of any kind.

