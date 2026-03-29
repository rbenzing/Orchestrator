# Routing Logic

## Phase Order
1. Discovery
2. Planning
3. Execution
4. Validation

## Routing Rules
- If no state → Discovery
- If requirements incomplete → Discovery
- If plan incomplete → Planning
- If tasks pending → Execution
- If tasks complete → Validation

## Tool Usage
- route-phase.ps1 decides next phase