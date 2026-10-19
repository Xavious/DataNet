# DataNet

## Description

A web browser inspired Mudlet package for Legends of the Jedi (LOTJ)

### Usage

Download the latest .mpackage file from the release page and install it like any other Mudlet package.

https://github.com/Xavious/DataNet/releases/tag/v1.2.0

Once installed you use it by clicking datanet links that you see in the game. The browser will automatically popup.

**Mouse Interactions**

- Add tab button
- Close tab button
- Back button
- Forward button
- Refresh button
- Cache index button (☰) - the list of pages you already have stored

Links
- **single click** - open page in the current tab
- **right click** - dropdown menu to open in the current tab or a new tab

New tabs open in the background, so clicking a link never yanks you away from what you were reading.

**Commands**
- `showdata` - show the popup window
- `hidedata` - hide the popup window
- `resetdata` - if the triggers break this will reset the captures (hopefully that doesn't happen)
- `datacache` - open the cache index

All four are also clickable in the DataNet line that prints after a page finishes loading.

### Features

**Each character gets its own browser**

Tabs, history and cached pages belong to the character you are logged in as. Log out and into an alt and you get that character's browser, not the one you just walked away from.

**Everything survives a restart**

Close the client, come back tomorrow, log in, and your tabs are where you left them with their contents intact. Saved per character inside your Mudlet profile directory.

**Offline browsing**

Every page you load is cached under its URL. Hit the ☰ button or type `datacache` to see everything you have stored:

- **Click a URL** to read the cached copy. Nothing is sent to the game, so it costs no charge and works even when you cannot fetch the page.
- **Click ↻** beside it to pull a fresh copy from the game instead.
- **Sort** by date or alphabetically by URL.
- **Clear** wipes the current character's cache, history and tabs. It asks before it does anything.

Links on a cached page stay clickable, same as a page you just loaded.

### Development

This is set up as a Muddler project to streamline development. Anyone interested in contributing needs to understand that paradigm.

Muddler
https://github.com/demonnic/muddler

Demuddler
https://github.com/Edru2/DeMuddler

Simplified walkthrough
https://mud.gesslar.dev/muddler.html

Helper example
https://gist.github.com/gesslar/c8ad4e3c52ba3df592e99b5388abf029

### Media

<img width="836" height="436" alt="image" src="https://github.com/user-attachments/assets/223ac530-a1e2-47ba-986d-a902ebc7239c" />

<img width="974" height="815" alt="image" src="https://github.com/user-attachments/assets/ae79c87e-f553-41de-b469-ddcad1dda097" />

<img width="102" height="61" alt="image" src="https://github.com/user-attachments/assets/5a34f144-5748-4621-8da2-5cbd48f088f4" />

<img width="112" height="75" alt="image" src="https://github.com/user-attachments/assets/bc611710-973b-4918-ac0e-323e5cf6328d" />

<img width="111" height="69" alt="image" src="https://github.com/user-attachments/assets/0183a160-4582-497d-b070-d12918e60b0d" />
