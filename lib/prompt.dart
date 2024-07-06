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
      "body": "sup arnoldas. just wanted to let you know, we got your s5 week #1 update — fk yea. btw -- if you need to make some changes to your update, click here. many people don't ever make it past step one. they overthink, and overcomplicate. but, you didn’t. keep it up. we'll see you in the next one."
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