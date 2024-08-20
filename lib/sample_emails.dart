// --IMPORTS--
import 'package:intl/intl.dart';

// --SAMPLE EMAILS FUNCTION--
List<Map<String, dynamic>> getSampleEmails() {
  return [
    {
      'subject': 'This Week in Tech: AI Breakthroughs and Privacy Concerns',
      'from': 'techdigest@example.com',
      'body': '''
Dear Tech Enthusiasts,

This week has been a whirlwind in the tech world. Here are the highlights:

1. OpenAI's GPT-5 Announcement: The next generation of language models is here, promising even more human-like interactions. But what are the ethical implications?

2. Apple's New Privacy Features: iOS 18 will introduce groundbreaking privacy controls. We break down what this means for users and advertisers.

3. The Chip Shortage: Finally Easing? We analyze the latest industry reports and what they mean for consumer electronics prices.

Stay curious and keep innovating!

The TechDigest Team
''',
    },
    {
      'subject': 'Mindful Monday: Embracing Change and Growth',
      'from': 'dailyzen@example.com',
      'body': '''
Hello Mindful Ones,

As we start a new week, let's focus on embracing change and fostering personal growth:

1. Meditation of the Week: "Flowing with Change" - A 10-minute guided meditation to help you adapt to life's constant shifts.

2. Wisdom Quote: "The only way to make sense out of change is to plunge into it, move with it, and join the dance." - Alan Watts

3. Weekly Challenge: Try one new thing each day, no matter how small. Share your experiences in our community forum!

Remember, every moment is an opportunity for growth.

Breathe deeply and live fully,
Your DailyZen Team
''',
    },
    {
      'subject': 'Gourmet Gazette: Seasonal Delights and Culinary Trends',
      'from': 'tastebud@example.com',
      'body': '''
Greetings, Food Lovers!

Spring is in full swing, and so are our taste buds! Here's what's cooking:

1. Ingredient Spotlight: Fiddlehead Ferns - These curly greens are the talk of farmers' markets. We share three delicious recipes to try.

2. Restaurant Review: "The Humble Radish" in Portland is redefining farm-to-table dining. Our critic gives it 4.5/5 stars!

3. Trend Alert: Fermentation Station - From kombucha to kimchi, fermented foods are having a moment. We explore the health benefits and how to start fermenting at home.

Happy cooking and bon appétit!

The Gourmet Gazette Team
''',
    },
  ];
}