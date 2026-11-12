# Converted from the communitybot legacy tests by kora-qa-panel/scripts/convert-legacy.mjs.
# The """ block under each Scenario is the original test text, verbatim. Review before applying.
Feature: kora_theme — game tests

  @kora_theme @legacy:theme-starts @target:1 @needs:admin
  Scenario: Resource starts cleanly
    """
    Needs a Mod.
    1. Mod restarts the resource with /server resource kora_theme.
    2. Mod watches the server console / txAdmin live console during the restart.
    3. Join or stay in game and press T to open chat.
    Expect: no red errors and no yellow [kora_theme] warnings about theme.json or fonts/catalog.json. Typing /theme in chat shows the suggestion "Choose your personal server colour scheme."
    """
    When I manually: ask a Mod to restart the resource with /server resource kora_theme
    And I manually: ask the Mod to watch the server console during the restart
    And I press the "T" key
    And I run the command "/theme"
    Then I confirm: the server console shows no red errors and no yellow [kora_theme] warnings about theme.json or fonts/catalog.json
    And I confirm: typing /theme in chat shows the suggestion "Choose your personal server colour scheme."

  @kora_theme @legacy:theme-picker-open @target:2
  Scenario: /theme opens the colour picker
    """
    1. Press T and type /theme (nothing after it).
    2. Look at the window that opens.
    3. Close it with the X, then open it again and close it with Done, then again and press Escape.
    Expect: a dark "Choose your colour" window with a row of round colour swatches (first is Kora green, then Crimson, Orange, Amber, Emerald, Cyan, Blue, Violet, Pink), a Custom colour box and a "Use server default" button. Every close method works and gives your mouse/camera back.
    """
    When I run the command "/theme"
    Then I confirm: a dark "Choose your colour" window opens
    And I confirm: it shows round swatches in order Kora green, Crimson, Orange, Amber, Emerald, Cyan, Blue, Violet, Pink
    And I confirm: it shows a Custom colour box and a "Use server default" button
    When I manually: close the window with the X
    Then I confirm: the window closes and my mouse and camera control return
    When I run the command "/theme"
    And I manually: close the window with the Done button
    Then I confirm: the window closes and my mouse and camera control return
    When I run the command "/theme"
    And I manually: press Escape
    Then I confirm: the window closes and my mouse and camera control return

  @kora_theme @legacy:theme-preset-live @target:2
  Scenario: Picking a preset recolours UIs straight away
    """
    1. Press T and type /theme.
    2. Click the Violet swatch, then click Done.
    3. Look at the HUD, open chat (T) and open your inventory (TAB).
    4. Repeat with a different swatch (e.g. Cyan).
    Expect: the clicked swatch gets a tick. The accent colour (highlights, buttons, bars, the "Appearance" label in the picker) changes to the new colour at once in the picker, HUD, chat and inventory, with no reconnect needed.
    """
    When I run the command "/theme"
    And I manually: click the Violet swatch, then click Done
    And I open my inventory
    And I press the "T" key
    Then I confirm: the Violet swatch got a tick in the picker
    And I confirm: the accent colour is violet at once in the picker, HUD, chat and inventory with no reconnect
    When I manually: repeat with a different swatch, e.g. Cyan
    Then I confirm: the accent colour changes to the new colour at once in the picker, HUD, chat and inventory

  @kora_theme @legacy:theme-custom-colour @target:2
  Scenario: Custom colour box applies any colour
    """
    1. Type /theme in chat.
    2. In Custom colour, click the colour square and pick any colour not in the presets.
    3. Check the code next to it updates (e.g. #12AB34), then click Apply.
    4. Click Done and open your inventory (TAB).
    Expect: the code shown matches the colour you picked, Apply turns the accent everywhere to that colour, and no swatch shows a tick (it is not a preset).
    """
    When I run the command "/theme"
    And I manually: in Custom colour, click the colour square and pick any colour not in the presets
    Then I confirm: the code next to the square updates to match the picked colour (e.g. #12AB34)
    When I manually: click Apply
    And I manually: click Done
    And I open my inventory
    Then I confirm: the accent is the picked colour everywhere
    And I confirm: no swatch shows a tick

  @kora_theme @legacy:theme-cmd-hex @target:2
  Scenario: /theme with a colour code, and a bad code
    """
    1. In chat type /theme #F97316 and press Enter.
    2. Type /theme 3b82f6 (no # sign).
    3. Type /theme banana.
    4. Type /theme #12345 (only 5 digits).
    Expect: step 1 turns the accent orange and step 2 turns it blue without opening the picker. Steps 3 and 4 do not change the colour and show a chat message from Theme: "Use a six-digit hex colour such as #7C3AED, or reset."
    """
    When I run the command "/theme #F97316"
    Then I confirm: the accent turns orange and the picker does not open
    When I run the command "/theme 3b82f6"
    Then I confirm: the accent turns blue and the picker does not open
    When I run the command "/theme banana"
    Then the chat should show "Use a six-digit hex colour such as #7C3AED, or reset."
    And I confirm: the colour does not change
    When I run the command "/theme #12345"
    Then the chat should show "Use a six-digit hex colour such as #7C3AED, or reset."
    And I confirm: the colour does not change

  @kora_theme @legacy:theme-reset @target:2
  Scenario: Reset back to the server colour
    """
    1. Set a colour, e.g. /theme #EC4899 (pink).
    2. Type /theme reset.
    3. Set pink again, then type /theme default.
    4. Set pink again, open /theme and click "Use server default".
    Expect: every method puts the accent back to the server's Kora green in all UIs straight away. The custom colour code in the picker shows #95FF00 after resetting.
    """
    When I run the command "/theme #EC4899"
    And I run the command "/theme reset"
    Then I confirm: the accent is back to Kora green in all UIs straight away
    When I run the command "/theme #EC4899"
    And I run the command "/theme default"
    Then I confirm: the accent is back to Kora green in all UIs straight away
    When I run the command "/theme #EC4899"
    And I run the command "/theme"
    And I manually: click "Use server default"
    Then I confirm: the accent is back to Kora green in all UIs straight away
    And I confirm: the custom colour code in the picker shows #95FF00

  @kora_theme @legacy:theme-persist @target:2
  Scenario: Your colour is kept after reconnecting
    """
    1. Set a clear colour, e.g. /theme #DC143C (crimson).
    2. Quit the game fully and reconnect to the server.
    3. Watch the loading screen, then the character select screen.
    4. Spawn in and check the HUD, chat and /theme picker.
    Expect: you are still on crimson after reconnecting (the picker shows Crimson ticked). The character select and HUD use crimson. The loading screen should also use it (on the first reconnect it may only switch to it partway through).
    """
    When I run the command "/theme #DC143C"
    And I manually: quit the game fully and reconnect to the server
    And I manually: watch the loading screen, then the character select screen
    And I manually: spawn in
    And I press the "T" key
    And I run the command "/theme"
    Then I confirm: I am still on crimson and the picker shows Crimson ticked
    And I confirm: the character select and HUD use crimson
    And I confirm: the loading screen uses crimson (on the first reconnect it may only switch partway through)

  @kora_theme @legacy:theme-per-player @target:2 @needs:players:2
  Scenario: Your colour only changes your own screen
    """
    Needs 2 players.
    1. Player A types /theme #7C3AED (violet). Player B leaves theirs on default.
    2. Both open chat (T) and the inventory (TAB) and compare screens, e.g. on Discord screenshots.
    3. Player B types /theme reset.
    Expect: only Player A sees violet. Player B still sees Kora green, and Player B's reset does not change Player A's colour.
    """
    When I manually: ask a second player (Player B) to leave their colour on default
    And I run the command "/theme #7C3AED"
    And I press the "T" key
    And I open my inventory
    And I manually: ask Player B to open chat and their inventory too
    And I manually: ask Player B to type /theme reset
    Then I confirm: only I see violet
    And I confirm: the other player still sees Kora green on their screen
    And I confirm: the other player's reset did not change my colour

  @kora_theme @legacy:theme-contrast @target:2
  Scenario: Button text stays readable on light and dark colours
    """
    1. Type /theme #FFFF00 (bright yellow) and open /theme again.
    2. Read the text on the Apply and Done buttons.
    3. Type /theme #1E1B4B (very dark blue) and open /theme again.
    4. Read the same buttons, and look at a highlighted button in the inventory (TAB).
    Expect: on yellow the button text is dark; on the dark blue it turns white. Text is easy to read in both cases. Run /theme reset when finished.
    """
    When I run the command "/theme #FFFF00"
    And I run the command "/theme"
    Then I confirm: the text on the Apply and Done buttons is dark and easy to read on yellow
    When I run the command "/theme #1E1B4B"
    And I run the command "/theme"
    Then I confirm: the text on the Apply and Done buttons is white and easy to read on dark blue
    When I open my inventory
    Then I confirm: a highlighted button in the inventory has readable white text
    When I run the command "/theme reset"

  @kora_theme @legacy:theme-look-lib @target:2
  Scenario: Notifications, menus, dialogs, progress bar match the theme
    """
    1. In chat type /testnotify, then /testmenu, then /testinput, then /testprogressbar.
    2. Compare each one with the /theme picker and your inventory (TAB).
    3. Set /theme #06B6D4 (cyan) and run the four commands again.
    Expect: all use the same dark panels, font, rounded corners and green accent (success, selected option, focused field, progress bar). After the change to cyan the accent in all of them is cyan. Run /theme reset after.
    """
    When I run the command "/testnotify"
    And I run the command "/testmenu"
    And I run the command "/testinput"
    And I run the command "/testprogressbar"
    And I run the command "/theme"
    And I open my inventory
    Then I confirm: the notification, menu, dialog and progress bar use the same dark panels, font, rounded corners and green accent as the picker and inventory
    When I run the command "/theme #06B6D4"
    And I run the command "/testnotify"
    And I run the command "/testmenu"
    And I run the command "/testinput"
    And I run the command "/testprogressbar"
    Then I confirm: the accent in all four is cyan
    When I run the command "/theme reset"

  @kora_theme @legacy:theme-look-screens @target:2
  Scenario: Inventory, clothing, chat and HUD look like one set
    """
    1. Open the inventory (TAB), then close it.
    2. Type /testclothing_wardrobe to open the wardrobe, then close it.
    3. Press T to open chat, and type /hudlayout to open the HUD layout editor.
    4. Compare them.
    Expect: same dark background, same font, same accent colour on selected items/buttons and similar rounded corners. Nothing looks unstyled (white background, Times New Roman font, plain grey buttons). Report any screen that looks different, with a screenshot.
    """
    When I open my inventory
    And I manually: close the inventory
    And I run the command "/testclothing_wardrobe"
    And I manually: close the wardrobe
    And I press the "T" key
    And I run the command "/hudlayout"
    Then I confirm: inventory, wardrobe, chat and HUD layout editor share the same dark background, font, accent colour and rounded corners
    And I confirm: nothing looks unstyled (no white background, Times New Roman font or plain grey buttons)

  @kora_theme @legacy:theme-look-join @target:2
  Scenario: Loading and character select screens match the theme
    """
    1. Run /theme reset, then quit and reconnect.
    2. Look at the loading screen while it loads.
    3. Look at the character select screen (create and select buttons, character cards).
    4. Spawn in and open the inventory (TAB) to compare.
    Expect: the loading screen and character select use the same dark colours, font and Kora green accent as the in-game UIs. No flash of unstyled white page or plain fonts that stays on screen.
    """
    When I run the command "/theme reset"
    And I manually: quit the game and reconnect
    And I manually: look at the loading screen while it loads
    Then I confirm: the loading screen uses the same dark colours, font and Kora green accent as the in-game UIs
    When I manually: look at the character select screen
    Then I confirm: the character select (create and select buttons, character cards) uses the same dark colours, font and Kora green accent
    When I manually: spawn in
    And I open my inventory
    Then I confirm: the inventory matches the loading and character select screens
    And I confirm: no flash of unstyled white page or plain fonts stays on screen

  @kora_theme @legacy:theme-fonts-config @target:1 @needs:admin
  Scenario: Admin font change applies to open UIs live
    """
    Needs a Mod (needs config edit access).
    1. A tester keeps chat (T) open; the Mod opens their inventory.
    2. Mod types /config, picks kora_theme, then fonts, and sets Body font to Oswald and Heading font to Poppins.
    3. Check the open UIs, then open /theme and /testmenu.
    4. Mod sets both back to "Server default (theme.json)".
    Expect: text in the open UIs changes font within a second, for every player, without closing anything. Newly opened UIs also use it. Step 4 brings the normal font back.
    """
    When I press the "T" key
    And I manually: ask a second player to keep chat open and open their inventory
    And I run the command "/config"
    And I manually: pick kora_theme, then fonts, and set Body font to Oswald and Heading font to Poppins
    Then I confirm: text in the open UIs changes font within a second for every player without closing anything
    When I run the command "/theme"
    And I run the command "/testmenu"
    Then I confirm: the newly opened UIs also use the new fonts
    When I manually: set both fonts back to "Server default (theme.json)"
    Then I confirm: the normal font is back

  @kora_theme @legacy:theme-restart @target:1 @needs:admin
  Scenario: UIs keep their look when the theme is restarted
    """
    Do this when few players are on. Most UIs depend on kora_theme, so a restart can stop them; if anything stays broken, a full server restart fixes it.
    Needs a Mod.
    1. A tester sets /theme #F97316 (orange) and opens the /theme picker.
    2. Mod runs /server resource kora_theme.
    3. Tester checks the screen, then opens chat (T), the inventory (TAB) and /theme again.
    Expect: the open picker closes and the mouse is released. HUD, chat and inventory keep their dark look and orange accent (no loss of colours). /theme still works and still shows orange as chosen. Tester runs /theme reset after.
    """
    When I run the command "/theme #F97316"
    And I run the command "/theme"
    And I manually: run /server resource kora_theme
    Then I confirm: the open picker closes and my mouse is released
    And I confirm: the HUD keeps its dark look and orange accent
    When I press the "T" key
    And I open my inventory
    Then I confirm: chat and inventory keep their dark look and orange accent
    When I run the command "/theme"
    Then I confirm: the picker still works and shows orange as chosen
    When I run the command "/theme reset"
