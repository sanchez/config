---
description: "Details about the AGENTS.md file. What it is, how to create it, and what should be included"
---

AGENTS.md is a convention used to provide documentation for the currently open codebase. By default, it is loaded into the Coding Assistants at runtime automatically, therefore it should be well structured, dense, and correct.

AGENTS.md should have the following sections:

# Codebase Architecture

Outline the key architectural decisions of the codebase.

- What does the infrastructure look like?
- What's the tech stack?
- What are the key modules?
- How do things interface with each other?

I would expect to see a breakdown of the codebase and how it physically maps between files and folders on disk to the high level modules/separations in the theory of the architecture. Treat this like a quick reference guide to the entire codebase. I should be able to answer questions like "Is there auth code, and where is it?" using this section.

# Coding Conventions

Include the common coding conventions used within the codebase. These can be software design patterns and coding style preferences. How the blocks of code are organized or ways of managing cognitive complexity. Make sure to capture the personal styling, how the code itself is structured in terms of spacing/pacing/identity.

As technique/brushwork is to an artist a description of how they achieve perfection, then this section should describe how the codebase achieves its perfection.

This section should be extensive, make sure to capture all the styles and characteristics of how the user codes. For example:

- How does the user structure blocks of code, when/where do they leave spaces, what's the rules for how this is completed
- When to break things up over multiple lines vs a single line
- How are functions and arguments structured
- How are classes designed, what are recurring rules in the codebase
- And many more.

The goal should be to capture all the inherit rules of the codebase so that someone could perfectly mimick the style of the codebase. This section is the most important to capture.

# Beware Of

Include things to watch out for, design decisions that might not be obvious on the surface. Or things that seemingly run counter to how someone new/fresh might understand

# Key System Goals

What is the codebase trying to achieve, what's the features, the goals, the priorities. This will be used by later assistants to understand what is important and where to focus effort.
