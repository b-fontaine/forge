# /forge:new <name> — Start a New Feature (Shortcut)

## Purpose
Shortcut combining `/forge:propose` and `/forge:specify` in one flow.

## Process
1. Run `/forge:propose <name>` flow
2. On proposal confirmation → immediately run `/forge:specify <name>`
3. On spec completion → prompt for `/forge:design <name>`

## If Detailed Description Provided
If user provides a detailed description (e.g., `/forge:new user-auth "Users should be able to log in with email and Google OAuth, with biometric fallback on mobile"`):

- Skip interactive proposal questions
- Auto-generate proposal from the description
- Proceed directly to spec writing
- Still run constitutional compliance gate

## Usage Examples
```
/forge:new user-authentication
/forge:new "product search" "Full-text search with filters, voice input, and personalized results"
/forge:new payment-integration
```
