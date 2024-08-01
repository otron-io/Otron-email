const String emailSummaryPrompt = '''
Please read all of these emails: {Placeholder for raw email data}

Instructions:
Please summarize the email newsletters for the past week into a spoken language narrative suitable for audio playback. Imagine you are hosting a personalized podcast or radio show called "Your Email Podcast," where you bring listeners the latest highlights from their inbox. The summary should include:
- The most significant news or updates
- A brief overview of any important events
- Key insights or takeaways from articles
- Any important statistics or figures
- Calls to action, if any
- The subject lines of the emails
- The names of the newsletters or senders
- Specific details from the email body to provide a clear understanding of the content

Ensure the language is clear and natural for audio playback, as if reading aloud to a listener. Narrate the output in the style and tone of the newsletter itself, using specific phrases and maintaining the original style. Start with an engaging introduction to set the stage for the podcast. Please add snarky/observant commentary reviewing the content yourself.
View the emails from the same sender as a holistic picture and notice any connections or storylines between them.

Example Input:
{
  "emails": [
    {
      "subject": "ur a legend – update #1 submitted.",
      "sender": "buildspace",
      "body": "sup arnoldas. just wanted to let you know, we got your s5 week #1 update — fk yea. btw -- if you need to make some changes to your update, click here. many people don't ever make it past step one. they overthink, and overcomplicate. but, you didn't. keep it up. we'll see you in the next one."
    },
    {
      "subject": "n&w s5 -- w1 wrap up. ty all.",
      "sender": "Farza",
      "body": "hey s5. lab #1 was actually really fun. we reviewed ~20 ideas of yours live with the team + guests. YouTube recording to lecture #1 here, lab #1 here. (the streams aren't actually 2+hrs long btw, we just do lofi cowork sessions at the end) weekly 1 update due in 3-days. next steps: read through the week 1 guide if you haven't. submit the week 1 update directly to sage using the form here. rsvp for the next two streams here (click in on each one, and rsvp individually). and, if you missed kickoff, go here. that's all! really happy that most people are being really nice to each other online/with their feedback :). okay, bye everyone have fun. p.s: if you wanna make a meme with josh, here you go lol. - farza"
    }
  ]
}

Example Output:
"Welcome to 'Your Email Podcast,' where we bring you the latest highlights from your inbox. This week, we have some exciting updates from buildspace and Farza.

First, an email from buildspace with the subject 'ur a legend – update #1 submitted.' They gave a big shoutout for getting your s5 week #1 update in. Buildspace said 'fk yea' because many people don't make it past step one, but you nailed it without overthinking. If you need to tweak anything, there's a link in the email to make changes. Buildspace is stoked and can't wait to see you crush it in the next update. Keep it up!

Next, an email from Farza titled 'n&w s5 -- w1 wrap up. ty all.' Lab #1 was a hit, with about 20 ideas reviewed live with the team and guests. If you missed it, YouTube recordings are available for lecture #1 and lab #1. Remember, the weekly 1 update is due in 3 days. Make sure to read through the week 1 guide and submit your update directly to Sage using the provided form. Also, don't forget to RSVP for the next two streams individually. Farza is pleased to see the positive interactions and feedback among participants. There's also a meme opportunity with Josh if you're interested!

That's all for this week's highlights. Stay updated and keep up the great work!"
''';

const String emailUrlExtractionPrompt = '''
Please read all of these emails: {Placeholder for raw email data}

Instructions:
Review all the content of the emails and extract any relevant URLs. Emails will have lots of unnecessary URLs for content in the email and other gimmicks, but we only want a list of URLs that were meant as calls to action. You should also return a clear indication of what the link is about, like:

RSVP to event: www.rsvpweb.com/event/123

Example Input:
{
  "emails": [
    {
      "subject": "ur a legend – update #1 submitted.",
      "sender": "buildspace",
      "body": "sup arnoldas. just wanted to let you know, we got your s5 week #1 update — fk yea. btw -- if you need to make some changes to your update, click here. many people don't ever make it past step one. they overthink, and overcomplicate. but, you didn't. keep it up. we'll see you in the next one."
    },
    {
      "subject": "n&w s5 -- w1 wrap up. ty all.",
      "sender": "Farza",
      "body": "hey s5. lab #1 was actually really fun. we reviewed ~20 ideas of yours live with the team + guests. YouTube recording to lecture #1 here, lab #1 here. (the streams aren't actually 2+hrs long btw, we just do lofi cowork sessions at the end) weekly 1 update due in 3-days. next steps: read through the week 1 guide if you haven't. submit the week 1 update directly to sage using the form here. rsvp for the next two streams here (click in on each one, and rsvp individually). and, if you missed kickoff, go here. that's all! really happy that most people are being really nice to each other online/with their feedback :). okay, bye everyone have fun. p.s: if you wanna make a meme with josh, here you go lol. - farza"
    }
  ]
}

Example Output:
[
  {
    "description": "Make changes to your update",
    "url": "https://www.buildspace.com/update/modify"
  },
  {
    "description": "YouTube recording to lecture #1",
    "url": "https://www.youtube.com/watch?v=lecture1"
  },
  {
    "description": "YouTube recording to lab #1",
    "url": "https://www.youtube.com/watch?v=lab1"
  },
  {
    "description": "Submit the week 1 update directly to Sage",
    "url": "https://www.sage.com/submit/update1"
  },
  {
    "description": "RSVP for the next two streams",
    "url": "https://www.eventbrite.com/e/stream1"
  },
  {
    "description": "Missed kickoff",
    "url": "https://www.buildspace.com/kickoff"
  }
]

Please only return JSON - no other words, keys or anything else, just pure json.
''';

const String efficientDailyEmailSummaryPrompt = '''
Analyze the following email data. Note that the email content has been cleaned and may be truncated:

{Placeholder for raw email data}

Instructions:
Create a concise, efficient daily podcast script summarizing the key information from various emails. The podcast is called "Your Daily Email Digest." Follow these guidelines:

	1.	Prioritize content-rich newsletters and emails that share stories and provide insights.
	2.	Group information by topics or themes, not by individual emails, but do not use TOPIC headers. Just incorporate the group names into the scrip.
	3.	Separate action-based or advertisement content into a brief bullet point section.
	4.	Include specific facts, figures, or deadlines when relevant.
	5.	Mention the sources (email senders) for context, but focus on the content.
	6.	Aim for a length that can be comfortably read in about 2-3 minutes.
	7.	Ensure the content is suitable for an audio transcript, avoiding long URLs or details that are impractical to read aloud.
	8.	Use natural, conversational transitions to connect information.
	9.	Indicate if there is more detailed content available in the full email or through provided links.

Structure:

	1.	Brief introduction
	2.	3-10 main points or topics, each summarized in 2-5 sentences:
	•	Present the information with necessary details
	•	Smoothly transition to its importance or actionable insight
	•	Indicate if there is more detailed content available in the full email
	3.	Action-based or advertisement content in a brief bullet point section
	4.	Quick mention of any less critical but noteworthy items

Example Output:
"Welcome to Your Daily Email Digest for July 31, 2024. Let's dive into what's important today.

In financial news, The New York Times reports that the Federal Reserve has decided to keep interest rates unchanged for now. However, they’ve hinted at possible rate cuts on the horizon. This could have major impacts on borrowers and investors, so keep an eye out for future announcements and think about how it might affect your financial plans. You can find more details in the full email.

Moving on to politics and elections, breaking news from The New York Times: Kari Lake has won the Senate primary in Arizona. She’s now set for a high-stakes race against Democrat Ruben Gallego. This is definitely an election to watch closely. Further details and context are available in the full email.

Now, in tech and AI updates, Google’s Project IDX is getting some big enhancements. It now includes in-browser support for React Native, AI tools for generating comments and tests, new database templates, and soon, Android Studio will be available in-browser. This could really change the game for app development. Meanwhile, AMD’s data center revenue has doubled, driven by AI chip sales, signaling a booming demand for AI solutions. This trend could have significant implications for the tech industry.

An financial news, The New York Times reports that the Federal Reserve has decided to keep interest rates unchanged for now. However, they’ve hinted at possible rate cuts on the horizon. This could have major impacts on borrowers and investors, so keep an eye out for future announcements and think about how it might affect your financial plans. You can find more details in the full email.

Moving on to politics and elections, breaking news from The New York Times: Kari Lake has won the Senate primary in Arizona. She’s now set for a high-stakes race against Democrat Ruben Gallego. This is definitely an election to watch closely. Further details and context are available in the full email.

Now, in tech and AI updates, Google’s Project IDX is getting some big enhancements. It now includes in-browser support for React Native, AI tools for generating comments and tests, new database templates, and soon, Android Studio will be available in-browser. This could really change the game for app development. Meanwhile, AMD’s data center revenue has doubled, driven by AI chip sales, signaling a booming demand for AI solutions. This trend could have significant implications for the tech industry.

That's it for today's digest. Stay informed and have a productive day!"

Remember to maintain a professional yet engaging tone, focusing on delivering maximum value and actionable insights while indicating the availability of more detailed content when applicable.
''';

const String imagePrompt = '''
### Instructions and Template for Image Generation

Transcript: {Placeholder for transcript}

### Step 1: Extract Variables from Transcript

1. Read the Transcript: Analyze the provided information to identify the main topic or concept.
2. Define Variables:
   - Dark Color: The darker shade for the gradient.
   - Light Color: The lighter shade for the gradient.
   - Symbol: A single silhouette that represents the main topic.
   - Note: You should not use the concept of Covid, copyrighted material, or any other sensitive concepts that might trigger the model not to generate an image. Also, don't generate a concept of AI, newspaper, newsletter, email, or podcast.

### Step 2: Formulate the Prompt

Use the extracted variables to create a clear and concise prompt for the image generation.

### Prompt Template

Create a clean, modern, and professional background image with a gradient from {dark_color} to {light_color}. In the center, place a single silhouette of a {symbol}. The design should be minimalistic, avoiding any text or logos.

### Example Usage

Given the provided podcast information, let's extract the variables:

- Dark Color: Dark blue
- Light Color: Light blue
- Symbol: Rugby ball (representing the Olympics update)

### Formulated Prompt

Create a clean, modern, and professional background image with a gradient from dark blue to light blue. In the center, place a single silhouette of a rugby ball. The design should be minimalistic, avoiding any text or logos.
''';

const String podcastTitlePrompt = '''
Generate a catchy and informative podcast title based on the following description and date range. The title should be concise, engaging, and reflect the main topics or themes of the podcast content.

Description: {Placeholder for description}

Date Range: {Placeholder for date range}

Instructions:
1. Analyze the description to identify the main topics or themes.
2. Incorporate the date range into the title in a natural way.
3. Keep the title under 10 words if possible.
4. Make it catchy and intriguing to potential listeners.
5. Avoid using generic phrases like "Your Daily Email Digest" unless it's particularly relevant.

Now, generate a title based on the provided description and date range.
''';