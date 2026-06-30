# Visual Implementation — Wiki

Welcome. This wiki explains the **what**, **why**, and **how** of the Visual Implementation skill — a disciplined workflow for turning a visual source into design-system-grounded mobile UI.

If you just want to install and go, read the [README](../README.md) and [Installation](Installation.md). If you want to understand how the skill thinks, start with [Concepts](Concepts.md).

## Map

| Page | Read it when |
| --- | --- |
| [Installation](Installation.md) | You want to install, update, or remove the skill |
| [Concepts](Concepts.md) | You want the mental model behind the workflow |
| [Workflow](Workflow.md) | You want the ten phases explained, step by step |
| [Non-Negotiables](Non-Negotiables.md) | You want the hard rules and the failures they prevent |
| [References](References.md) | You want to know what each `references/*.md` file does |
| [Platforms](Platforms.md) | You work in Flutter / Compose / SwiftUI / UIKit / KMP |
| [FAQ](FAQ.md) | You have a specific "but what about…" question |

## The one-paragraph version

Treat the **visual source as the source of truth for intent**, the **existing project as the source of truth for implementation language**, and the **user as the source of truth for missing assets and ambiguous decisions**. Extract design intent precisely (tokens over pixels), map every region to existing project primitives before inventing anything, surface what is hard or unknown as a risk ledger, stop at a decision gate for choices you cannot make alone, implement from a concrete brief, and prove the result by **rendering your build and comparing it to the source property by property**.

## Source of truth

The skill itself is the [`visual-implementation/`](../visual-implementation/SKILL.md) directory. This wiki orients and explains; the skill files are authoritative. When the two disagree, the skill files win — and the wiki should be updated.
