---
name: langfood-ui-taste
description: Design, redesign, polish, or review LangFood Flutter screens and interactions for students, sellers, and shippers. Use for mobile UI and UX work, including "thiết kế lại giao diện". Scope is the LangFood app UI.
---

# LangFood UI Taste

## Start from the running app

Open the existing screen through its normal role entry point when possible. Inspect the current widget, theme, and data source. Identify what the user needs to notice first, the action they need next, and the state they should see afterward. On an existing screen, check those points before choosing a visual direction.

Use the [LangFood Stitch project](https://stitch.withgoogle.com/projects/8904364497132995449) for brand and flow context. Its student and shipper screens are references for adjacent flows. Use the [iOS design kit](https://www.figma.com/design/GGJWJDSfvWY89vdhUqazbP/?node-id=0-1) for legibility, grouped controls, and light and dark surfaces. Apply references to the requested flow and verify supported actions against the existing API.

## Design for the task

- Reuse `AppTheme`, `AppTokens`, `AppTypography`, and suitable `LangFood*` widgets in `langfood-flutter/lib/core/`. Use the existing brand orange and consistent spacing. Use a short label with each meaningful status color.
- For students, make the dish, quantity, price, pickup or delivery details, and next checkout step easy to scan. Use the app's actual menu data or clearly labeled fixtures.
- For sellers, put actionable orders ahead of secondary metrics. Keep all four order queues discoverable at phone widths, including **Lịch sử**. Make the order code, quantity, dish name, and kitchen notes easy to scan. Aim for 48–56 dp tap targets for frequent actions.
- For shippers, prioritize the next action and the pickup or handoff location. Show completion feedback when the corresponding operation succeeds.
- Use brief motion to signal a change, such as the selected queue, an updated count, or a confirmed action. Reserve moving accents for events that need attention. Respect reduced-motion settings and keep labels readable throughout the transition.

## Verify the flow

Check the changed UI on a representative narrow phone and with larger text. Check light and dark appearance where the screen supports both. Exercise the primary action and relevant loading, empty, and error states. Use fixture data for tests that mutate orders. Inspect the result in Flutter on an emulator, a connected device, or a mobile-width web preview as available. For a change to the signed-in app, verify the normal role route and identify whether the evidence came from a live or demo build.

Adapted for LangFood from [Leonxlnx's Taste Skill](https://github.com/Leonxlnx/taste-skill) under the [MIT license](LICENSE).
