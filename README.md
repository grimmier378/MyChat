  # MyChat
  By _Grimmier_
  
  ## Basic Chat Window. 
  
  ## *Features:*
  * Customizable channels and colors.
  * Reads settings from MyChat_Settings.ini in the MQ\Config dir. 
  * You can customize any event string you would like and create a channel for it that you can turn on of off at any time. 

  *example MyChat_Settings ini.*

   ```[ChannelName]=[EventString]=[FilterString]=[Color]```
  
  ```
      [Events_Channels]
      Ooc=#*#say#*# out of character,#*#=out of character=dkgreen
      Shout=#*#shout#*#,#*#=shout=red
      Auction=#*#auction#*#,#*#=auction=dkgreen
      XP=#*#gained#*#experience!#*#=experience!=dkyellow
      AA=#*#gained an ability point#*#=an ability point=orange
      Group=#*#tells the group#*#=group,=teal
      Guild=#*#tells the guild#*#=guild,=green
      Tells=#*#tells you,#*#=tells you,=magenta
      Say=#*#says,#*#=says,=white
```
  
  ChannelName is what shows in your menu to toggle on or off. anything you want to name it.
  EventString is the search pattern that will trigger the event to write to console.
  FilterString is used in the lua parse to determine what channel the line belongs to. key search word to match to channel.
  Color what color do you want that channels lines to be?
                
   ## *valid colors*
    green           dkgreen
    red             dkred
    teal            dkteal
    orange          dkorange
    magenta         dkmagenta
    purple          dkpurple
    yellow          dkyellow
    blue            dkblue
    white   grey    black
