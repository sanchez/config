---
description: "Documentation on how to create or understand how to create skills"
---

Skills should be brief pieces of documentation containing key pieces of information that allow the reader to understand the high level technical details and provide links/references to be able to easily investigate further

# Description
All skills should have a description frontmatter, this description should describe what the skill achieves. This description will be the piece of information the assistant uses to decide if the skill is relevant to the task at hand or not

# Creating a Skill
All skills are located inside the `skills` directory at the top level of the current working directory. A skill has the filename of `<name>.md`. Together `name` and `description` will be the indicators used by the model to select the skill for the job.

