Product Requirements Document (PRD)
DEVPOST TEAM: https://devpost.com/software/1161788/joins/6z9DEh6Kd3moeoD60lAEIA 
Product Name (working): ock
Version: v0 (Base Zero)
Primary Track: Education

1. Problem Statement (Reframed)
Students can learn on their own — but when they’re unfamiliar with new material, doing so is dramatically slower and less efficient without guidance.
When a student studies alone:
They reread notes repeatedly
They Google fragmented explanations
They’re also constantly switching between tasks, which is causing attention residue which negatively affects their studying
They lose time trying to map explanations back to their course or finding the right content in their materials
Small misunderstandings compound into larger gaps which lead to bigger issues in their academic performance
When a student studies with a TA, progress accelerates:
Confusion is resolved exponentially faster
Explanations are contextualized to the course and the students strengths
Time spent stuck drops significantly
The problem is not capability — it’s inefficiency and wasted time when help isn’t instantly available.

2. Product Vision
Provide a personal, always-available Teaching Assistant that:
Is trained on your exact course materials
Can see what you’re seeing in real time
Responds conversationally like a real TA (CRITICAL)
Explains concepts using your notes, your textbook, your materials and external/general knowledge if that is not enough
It should do this in a way where the assistant prioritises the students' learning instead of trying to get them an answer as soon as possible
This mimics the experience of sitting beside a TA while studying.

3. Target User
Primary User
University/college students
Studying math, CS, engineering, sciences, or theory-heavy courses
Anybody who wants to learn something
Use Context
Studying alone
Working through practice problems
Reviewing lecture slides or textbook examples
Late-night or off-hours learning

4. Core Use Case (Primary Flow)
User uploads course materials:
Lecture notes (PDF)
Textbook chapters (PDF)
Optional: practice sets, slides, handouts that they will be working on 
User starts a study session
Screen is shared (live)
TA is “present” in the session
User gets confused
Points verbally or visually to content/uses semantic and contextual reasoning to understand what the user is referencing
Asks a natural question:
“This equation right here, I don’t understand how they got the roots.”
TA responds conversationally:
Uses user’s uploaded materials
References relevant definitions/examples
Explains step-by-step
Matches course notation and language

5. MVP Scope (v0)
In Scope (Must Have)
A. Document Ingestion
Upload PDFs (notes, textbook, slides)
Text extraction + chunking
Course-scoped knowledge base
No auto-scraping, no LMS integration (manual upload only)
B. Contextual Q&A
Conversational chat interface
Queries answered only from uploaded materials
Citations or references to source sections (conversational citation + pull up the source on the homepage)
C. Screen Awareness (Minimal)
User shares screen
System extracts:
Visible text (OCR)
Diagrams/pictures
Basic layout context
v0 does not require perfect vision understanding
Just enough to anchor “this equation here”
D. Conversational Interface
Voice input OR text input
Natural TA-style responses
Calm, explanatory tone
Step-by-step breakdowns

6. Functional Requirements
6.1 User Accounts
Email or magic link login
Single user, single course workspace

6.2 Course Workspace
One active course per workspace
Upload + manage documents
Documents tagged to the course only

6.3 Study Session
Start / end session
Enable screen sharing or capture
Activate TA presence

6.4 Question Handling
Input:
Voice (preferred)
Text (fallback)
Question is enriched with:
Visible screen text
Relevant document chunks
Response includes:
Explanation
References to notes/textbook sections
Optional worked example

7. Sponsor Software Used
Wispr Flow (speech → text)
What it does: Converts the student’s voice into text quickly/accurately.
How ock uses it: Student talks normally → Wispr produces the transcript you feed into your TA logic.
What you still code: mic controls (push-to-talk / hotkey), handling partial vs final transcripts, “wake”/stop listening logic, and mapping vague phrases (“this one”) to your current screen-context window.
ElevenLabs (text → voice)
What it does: Turns your TA’s text response into natural-sounding speech.
How ock uses it: Your generated explanation → ElevenLabs speaks it back like a TA.
What you still code: when to speak vs stay silent, chunking long explanations into segments, barge-in policy (if user talks, do you stop speaking?), and UI playback controls.
The Token Company (LLM input compression)
What it does: Shrinks the text you send into the LLM (fewer tokens) while keeping meaning.
How ock uses it: Compress retrieved note chunks + relevant screen text before sending to the LLM → cheaper/faster responses and room for more context.
What you still code: document ingestion (PDF → text), chunking, embeddings/RAG retrieval, “what to include” ranking, and the policy that prevents answers outside course content.

8. Targets Tracks to Win
Education Main: $2000, $1000, $500
Wispr Flow Sponsor: 1 Year wispr flow pro, unique key, wispr swag (2/5)
ElevenLabs: 6 Months of ElevenLabs Scale tier (3/5)
The Token Company: $1000, $500, $500

9. Additional Things To Do
Recommendation from Zak : expand on what this can do in the future and stuff

10. v1
Overlays (citations, alerts)
Vision inference selection
Overlay branching + elaboration