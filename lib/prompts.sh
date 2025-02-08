# lib/prompts.sh
# This file contains the prompt instructions used by Autocommit.
JIRA_INSTRUCTIONS="JIRA_INSTRUCTIONS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    Generate a Jira ticket title and description.

    **Requirements:**

    - **Title:** A concise, goal-oriented title for the task to be done.
    - **Description:** A detailed explanation of what needs to be implemented, focusing on high-level objectives and goals.

    **Important:**
    
    - **Provide only the title and description. Do not include any introductory or concluding sentences.**
    - **Do not add explanations, summaries, or lists of changes.**
    
    **Output Format:**
    
    Title: [Your Title]
    Description: [Your Description]
    
    **Example:**
    
    Title: FEAT: Implement user authentication
    Description: Add user login and registration functionality using OAuth 2.0. Ensure secure password storage and session management.
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< JIRA_INSTRUCTIONS END"

PR_INSTRUCTIONS="PR_INSTRUCTIONS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    Create a Pull Request title and description.

    **Requirements:**

    - **Title:**
        - Start with one of these categories: FEAT, BUGFIX, REFACTOR, CHORE, CICD, ETC.
        - If a Jira ticket number is available, include it in the format: [ABC-123].
        - Format: CATEGORY: [JIRA_TICKET_NUMBER] A concise summary of changes.

    - **Description:**
        - Provide a detailed summary of the changes made.
        - Highlight key features, fixes, or improvements.
        - Focus on the purpose and impact of the changes.

    **IMPORTANT:**
    
    - **Provide only the title and description.**
    - **Do not include any introductory or concluding sentences.**

    **Output Format:**
    
    Title: CATEGORY: [JIRA_TICKET_NUMBER] Summary
    Description: Detailed description
    
    **Example:**
    
    Title: FEAT: [ABC-123] Add user authentication
    Description: Implemented OAuth 2.0 for user login and registration. Ensured secure password storage and session management.
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< PR_INSTRUCTIONS END"

COMMIT_INSTRUCTIONS="COMMIT INSTRUCTIONS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    Generate a concise git commit message summarizing the key changes.

    **Requirements:**

    - Start with one of these categories: FEAT, BUGFIX, REFACTOR, CHORE, CICD, ETC.
    - Include the Jira ticket number if available in the format: [ABC-123].
    - Format the commit message as:
        - **With ticket number:** CATEGORY:[JIRA_TICKET_NUMBER] A concise summary.
        - **Without ticket number:** CATEGORY: A concise summary.
    - Focus on the overall purpose and impact of the changes.
    - Combine smaller changes into meaningful descriptions.
    - Ignore any code reformatting or minor cleanups.
    
    **IMPORTANT:**

    - **Provide only the commit message.**
    - **Do not include any introductory or concluding sentences.**
    - **Do not add explanations, summaries, or lists of changes.**

    **Output Format:**
    
    CATEGORY:[JIRA_TICKET_NUMBER] A concise summary of changes.
    
    **Example:**
    
    FEAT:[ABC-123] Implement user authentication using OAuth 2.0.
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< COMMIT INSTRUCTIONS END
"

CONSISTENCY_INSTRUCTIONS="CONSISTENCY INSTRUCTIONS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    Format the following commit message according to these specifications:

    - Begin with the appropriate category (e.g., FEAT, BUGFIX, REFACTOR).
    - Include the Jira ticket number if present.
    - The final format should be: CATEGORY:[JIRA_TICKET_NUMBER] A concise summary of changes.
    - Preserve the structure of the message, including any bullet points or line breaks.
    
    **IMPORTANT:**

    - **Provide only the final commit message**
    - **Do not include any introductory or concluding sentences.**
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< CONSISTENCY INSTRUCTIONS END"