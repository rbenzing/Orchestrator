# Context Loading Policy

## Rules
- Load MAX:
  - 1 phase file
  - 1 gate file
  - state summary

## Never Load
- All phases simultaneously
- Full historical logs

## Use Summaries
- Use compressed state representation
- Only expand when needed

## Trigger Expansion
- Only when ambiguity detected