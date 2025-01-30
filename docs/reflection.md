In docs/reflection.md you should

Identify which of the course topics you applied (e.g. secure data persistence) and describe how you applied them
Describe what changed from your original concept to your final implementation? Why did you make those changes from your original design vision?
Discuss how doing this project challenged and/or deepened your understanding of these topics.
Describe two areas of future work for your app, including how you could increase the accessibility and usability of this 

**Identify which of the course topics you applied (e.g. secure data persistence) and describe how you applied them**
We applied the following course topics:
1. Properties of People: Vision
    - High contrast was applied with emphasis on font thickness
2. Properties of People: Motor Control (e.g. Fitts’s Law)
    - applied by making buttons either big, easy to press, and/or in the corners of the screen
3. Stateless & stateful widgets
    - The entire application uses a mix of stateless and stateful widgets, which was implemented on much of the Main view, add view, and edit view so elements could be dynamic
4. Querying web services
    - We connected to an API to get real stock data using a process similar to the weatherApp. However, this is not used by default because we also wanted to test with and demonstrate refresh functionality, but it works. you can change line 43 of the portfolioProvider to see it!
5. Undo and Redo
    - Undoing and redoing will return to previous add, edit, and commit states. we applied this 
6. Secure data persistence (using Hive)
    - secure data persistence similar to our journal app in order to keep the user's data consistent throughout multiple openings of the app as your investments wouldn't change between sessions. This meant that data persistence is a key aspect of our application. We also implemented the use of providers in order to get live data from our stocks, as well as 

**Describe what changed from your original concept to your final implementation? Why did you make those changes from your original design vision?**
Our original concept had a sightly different ui compared to our final implementation as we made changes in order to make the overall application look cleaner as well as be more accesible. Our rough drafts were mainly to layout the key buttons that were needed at a minimum for our functionality of our application so once we got those implemented we went around moving elements and stylizing the ui to make things look better.

**Discuss how doing this project challenged and/or deepened your understanding of these topics.**
This project challenged us as pulling data from an external api was a challenge we had to overcome as well as figuring out ways to overcome the issues with limited api tokens per day. 

**Describe two areas of future work for your app, including how you could increase the accessibility and usability of this app**
An area of future work could be our projection model, as it currently uses a very simple algorithm which most likely isn't the most accurate as if it was everyone would be able to profit off the market. Adding the option for switching between dark and light modes could be another accesibilty feature we could include, and adding voice control software support would help impaired users. 

**What do you feel was the most valuable thing you learned in CSE 340 that will help you beyond this class, and why?**
The most valuable thing I've learned in CSE 340 is my understanding of accesibilty, and how every design choice can and should have a meaning behind it. Before taking this class, a lot of my choices in applications weren't given much choice but now I realize the importance of accesibilty and how we need to not only account for every user but that by making specific design choices we can make applications more efficient and usable to everyone. 

**If you could go back and give yourself 2-3 pieces of advice at the beginning of the class, what would you say and why? (Alternatively: what 2-3 pieces of advice would you give to future students who take CSE 340 and why?)**
Starts your homework early and don't be afraid to go to office hours and ask questions when you aren't sure. 

**Citations**
StackOverflow, JournalApp (secure data storage), WeatherApp (querying web services) 

